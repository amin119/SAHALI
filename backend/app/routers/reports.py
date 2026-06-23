from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, Query
from sqlalchemy import func, text
from sqlalchemy.orm import Session
from geoalchemy2.functions import ST_DWithin, ST_MakePoint, ST_SetSRID
from typing import Annotated
import asyncio

from app.database import get_db
from app.models.report import Report, ReportStatus, ReportStatusHistory
from app.models.user import User, UserRole
from app.schemas.report import (
    ReportCreate, ReportOut, ReportListOut, StatusUpdate,
    CommentCreate, PresignedUrlRequest, PresignedUrlResponse
)
from app.utils.deps import get_current_user, require_staff, require_supervisor
from app.utils.pagination import PaginationParams
from app.utils.security import generate_tracking_code
from app.services.storage import generate_presigned_upload
from app.services.notification import notify_citizen, notify_staff
from app.services.ai_client import analyze_report
from app.services.event_bus import publish_report_event

router = APIRouter(prefix="/reports", tags=["reports"])

# Allowed forward status transitions
_TRANSITIONS: dict[ReportStatus, list[ReportStatus]] = {
    ReportStatus.SUBMITTED: [ReportStatus.RECEIVED, ReportStatus.REJECTED],
    ReportStatus.RECEIVED: [ReportStatus.UNDER_REVIEW],
    ReportStatus.UNDER_REVIEW: [ReportStatus.SCHEDULED, ReportStatus.REJECTED],
    ReportStatus.SCHEDULED: [ReportStatus.IN_PROGRESS],
    ReportStatus.IN_PROGRESS: [ReportStatus.RESOLVED, ReportStatus.UNDER_REVIEW],
    ReportStatus.RESOLVED: [ReportStatus.CLOSED],
    ReportStatus.CLOSED: [],
    ReportStatus.REJECTED: [],
}


def _report_to_out(r: Report) -> ReportOut:
    lat = lng = None
    if r.location is not None:
        from geoalchemy2.shape import to_shape
        pt = to_shape(r.location)
        lat, lng = pt.y, pt.x
    data = ReportOut.model_validate(r)
    data.lat = lat
    data.lng = lng
    return data


@router.post("/presigned-url", response_model=PresignedUrlResponse)
def get_presigned_url(
    body: PresignedUrlRequest,
    _: User = Depends(get_current_user),
):
    result = generate_presigned_upload(body.filename, body.content_type)
    return PresignedUrlResponse(**result)


@router.post("", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
def submit_report(
    body: ReportCreate,
    background: BackgroundTasks,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    tracking_code = generate_tracking_code()
    while db.query(Report).filter(Report.tracking_code == tracking_code).first():
        tracking_code = generate_tracking_code()

    point = f"SRID=4326;POINT({body.lng} {body.lat})"
    report = Report(
        tracking_code=tracking_code,
        citizen_id=current_user.id,
        category_id=body.category_id,
        title=body.title,
        description=body.description,
        photo_url=body.photo_url,
        thumbnail_url=body.thumbnail_url,
        location=point,
        address=body.address,
        city=body.city,
        ward=body.ward,
    )
    db.add(report)
    db.flush()

    history = ReportStatusHistory(
        report_id=report.id,
        from_status=None,
        to_status=ReportStatus.SUBMITTED,
        changed_by=current_user.id,
    )
    db.add(history)
    db.commit()
    db.refresh(report)

    background.add_task(_run_ai_analysis, report.id, body, current_user.preferred_language)
    background.add_task(_notify, db, report, "SUBMITTED")
    background.add_task(_notify_staff, report.id)

    publish_report_event("report_created", {
        "id": str(report.id),
        "tracking_code": report.tracking_code,
        "city": report.city,
        "category_id": report.category_id,
        "status": report.status.value,
        "priority": report.priority.value if report.priority else None,
    })

    return _report_to_out(report)


def _notify(db: Session, report: Report, event: str):
    try:
        notify_citizen(db, report, event)
        db.commit()
    except Exception:
        pass


def _notify_staff(report_id):
    try:
        from app.database import SessionLocal
        with SessionLocal() as db:
            r = db.get(Report, report_id)
            if r:
                notify_staff(db, r)
                db.commit()
    except Exception:
        pass


def _run_ai_analysis(report_id, body: ReportCreate, lang: str):
    async def _inner():
        result = await analyze_report(
            str(report_id), body.description or "", body.photo_url,
            body.lat, body.lng, lang
        )
        if result:
            from app.database import SessionLocal
            with SessionLocal() as sess:
                r = sess.get(Report, report_id)
                if r:
                    r.ai_category_id = result.get("category_id")
                    r.ai_confidence = result.get("ai_confidence")
                    r.is_duplicate = result.get("is_duplicate", False)
                    r.duplicate_of = result.get("duplicate_of")
                    if result.get("priority"):
                        r.priority = result["priority"]
                    sess.commit()
    asyncio.run(_inner())


@router.get("", response_model=ReportListOut)
def list_reports(
    pagination: Annotated[PaginationParams, Depends()],
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    status: ReportStatus | None = Query(None),
    category_id: int | None = Query(None),
    city: str | None = Query(None),
):
    query = db.query(Report)

    # Citizens only see their own reports
    if current_user.role == UserRole.citizen:
        query = query.filter(Report.citizen_id == current_user.id)
    # Field agents only see their assigned reports
    elif current_user.role == UserRole.field_agent:
        query = query.filter(Report.assigned_to == current_user.id)

    if status:
        query = query.filter(Report.status == status)
    if category_id:
        query = query.filter(Report.category_id == category_id)
    if city:
        query = query.filter(Report.city.ilike(f"%{city}%"))

    total = query.count()
    reports = query.order_by(Report.created_at.desc()).offset(pagination.offset).limit(pagination.page_size).all()

    return ReportListOut(
        items=[_report_to_out(r) for r in reports],
        total=total,
        page=pagination.page,
        page_size=pagination.page_size,
    )


@router.get("/nearby", response_model=list[ReportOut])
def reports_nearby(
    lat: float = Query(...),
    lng: float = Query(...),
    radius: int = Query(500, ge=50, le=10000),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    point = ST_SetSRID(ST_MakePoint(lng, lat), 4326)
    reports = (
        db.query(Report)
        .filter(ST_DWithin(Report.location.cast("geography"), point.cast("geography"), radius))
        .filter(Report.status.notin_([ReportStatus.CLOSED, ReportStatus.REJECTED]))
        .limit(50)
        .all()
    )
    return [_report_to_out(r) for r in reports]


@router.get("/tracking/{code}")
def public_tracking(code: str, db: Session = Depends(get_db)):
    report = db.query(Report).filter(Report.tracking_code == code).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return {
        "tracking_code": report.tracking_code,
        "status": report.status,
        "category_id": report.category_id,
        "city": report.city,
        "address": report.address,
        "created_at": report.created_at,
        "updated_at": report.updated_at,
    }


@router.get("/{report_id}", response_model=ReportOut)
def get_report(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if current_user.role == UserRole.citizen and report.citizen_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    return _report_to_out(report)


@router.patch("/{report_id}/status", response_model=ReportOut)
def update_status(
    report_id: str,
    body: StatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    allowed = _TRANSITIONS.get(report.status, [])
    if body.status not in allowed and current_user.role != UserRole.admin:
        raise HTTPException(
            status_code=400,
            detail=f"Transition {report.status} → {body.status} is not allowed"
        )

    history = ReportStatusHistory(
        report_id=report.id,
        from_status=report.status,
        to_status=body.status,
        changed_by=current_user.id,
        note=body.note,
    )
    db.add(history)

    report.status = body.status
    if body.status == ReportStatus.RESOLVED:
        from datetime import datetime, timezone
        report.resolved_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(report)

    notify_citizen(db, report, body.status.value)
    db.commit()

    publish_report_event("status_changed", {
        "id": str(report.id),
        "tracking_code": report.tracking_code,
        "status": report.status.value,
    })

    return _report_to_out(report)


@router.patch("/{report_id}/assign")
def assign_report(
    report_id: str,
    assignee_id: str,
    db: Session = Depends(get_db),
    _: User = Depends(require_supervisor),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    assignee = db.get(User, assignee_id)
    if not assignee:
        raise HTTPException(status_code=404, detail="Assignee not found")

    report.assigned_to = assignee.id
    db.commit()

    publish_report_event("report_assigned", {
        "id": str(report.id),
        "tracking_code": report.tracking_code,
        "assigned_to": str(assignee.id),
    })

    return {"message": "Assigned"}
