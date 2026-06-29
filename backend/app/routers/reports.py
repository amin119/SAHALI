from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, Query, UploadFile, File, Response
from fastapi.responses import StreamingResponse
import io
from sqlalchemy import func, text
from sqlalchemy.orm import Session
from geoalchemy2.functions import ST_DWithin, ST_MakePoint, ST_SetSRID
from typing import Annotated
import asyncio

from app.database import get_db
from app.models.report import Report, ReportStatus, ReportStatusHistory, Assignment, ResolutionReport
from app.models.user import User, UserRole
from app.schemas.report import (
    ReportCreate, ReportOut, ReportListOut, StatusUpdate,
    CommentCreate, PresignedUrlRequest, PresignedUrlResponse, PhotoUploadResponse,
    AssignCreate, AssignmentOut, ResolutionReportCreate, ResolutionReportOut,
    UserBrief,
)
from app.utils.deps import get_current_user, require_staff, require_supervisor
from app.utils.pagination import PaginationParams
from app.utils.security import generate_tracking_code
from app.services.storage import generate_presigned_upload, upload_photo as storage_upload_photo, get_photo as storage_get_photo
from app.services.notification import notify_citizen, notify_staff
from app.services.ai_client import analyze_report
from app.services.event_bus import publish_report_event

router = APIRouter(prefix="/reports", tags=["reports"])

# Allowed forward status transitions
_TRANSITIONS: dict[ReportStatus, list[ReportStatus]] = {
    ReportStatus.SUBMITTED:    [ReportStatus.RECEIVED, ReportStatus.REJECTED],
    ReportStatus.RECEIVED:     [ReportStatus.UNDER_REVIEW, ReportStatus.REJECTED],
    ReportStatus.UNDER_REVIEW: [ReportStatus.IN_PROGRESS, ReportStatus.REJECTED],
    ReportStatus.IN_PROGRESS:  [ReportStatus.RESOLVED, ReportStatus.REJECTED],
    ReportStatus.RESOLVED:     [],
    ReportStatus.REJECTED:     [],
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


def _assignment_to_out(a: Assignment) -> AssignmentOut:
    return AssignmentOut(
        id=a.id,
        agent=UserBrief(id=a.agent.id, full_name=a.agent.full_name, role=a.agent.role),
        assigned_by_user=UserBrief(id=a.assigner.id, full_name=a.assigner.full_name, role=a.assigner.role),
        note=a.note,
        is_active=a.is_active,
        created_at=a.created_at,
    )


def _resolution_to_out(rr: ResolutionReport) -> ResolutionReportOut:
    return ResolutionReportOut(
        id=rr.id,
        comment=rr.comment,
        materials=rr.materials,
        photo_url=rr.photo_url,
        resolved_by_user=UserBrief(id=rr.resolver.id, full_name=rr.resolver.full_name, role=rr.resolver.role),
        created_at=rr.created_at,
    )


@router.post("/presigned-url", response_model=PresignedUrlResponse)
def get_presigned_url(
    body: PresignedUrlRequest,
    _: User = Depends(get_current_user),
):
    result = generate_presigned_upload(body.filename, body.content_type)
    return PresignedUrlResponse(**result)


@router.get("/photo/{file_path:path}")
def proxy_photo(file_path: str):
    """Public proxy that streams a photo from MinIO. Used by mobile clients
    that cannot reach localhost:9000 directly."""
    try:
        data, content_type = storage_get_photo(file_path)
        return StreamingResponse(io.BytesIO(data), media_type=content_type,
                                 headers={"Cache-Control": "public, max-age=86400"})
    except Exception:
        raise HTTPException(status_code=404, detail="Photo not found")


@router.post("/photo", response_model=PhotoUploadResponse)
async def upload_report_photo(
    file: UploadFile = File(...),
    _: User = Depends(get_current_user),
):
    data = await file.read()
    filename = file.filename or "photo.jpg"
    content_type = file.content_type or "image/jpeg"
    result = storage_upload_photo(data, filename, content_type)
    return PhotoUploadResponse(**result)


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

    # Merge photo_urls: if photo_url was set directly (old clients), include it
    all_photo_urls = list(body.photo_urls)
    if body.photo_url and body.photo_url not in all_photo_urls:
        all_photo_urls.insert(0, body.photo_url)
    primary_photo = all_photo_urls[0] if all_photo_urls else body.photo_url

    point = f"SRID=4326;POINT({body.lng} {body.lat})"
    report = Report(
        tracking_code=tracking_code,
        citizen_id=current_user.id,
        category_id=body.category_id,
        title=body.title,
        description=body.description,
        photo_url=primary_photo,
        thumbnail_url=body.thumbnail_url or primary_photo,
        photo_urls=all_photo_urls,
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
    agent_id: str | None = Query(None),
):
    query = db.query(Report)

    if current_user.role == UserRole.citizen:
        query = query.filter(Report.citizen_id == current_user.id)
    elif current_user.role == UserRole.field_agent:
        # Field agents see reports assigned to them
        query = query.join(Assignment, Assignment.report_id == Report.id)\
                     .filter(Assignment.agent_id == current_user.id, Assignment.is_active == True)\
                     .filter(Report.status != ReportStatus.SUBMITTED)
    else:
        # Admin / supervisor / analyst see ALL reports including submitted
        if agent_id:
            query = query.join(Assignment, Assignment.report_id == Report.id)\
                         .filter(Assignment.agent_id == agent_id, Assignment.is_active == True)

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
        .filter(Report.status.notin_([ReportStatus.REJECTED]))
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

    # Auto-set analyzed_by when moving to UNDER_REVIEW
    if body.status == ReportStatus.UNDER_REVIEW and not report.analyzed_by:
        report.analyzed_by = current_user.id

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


@router.post("/{report_id}/assign", response_model=list[AssignmentOut])
def assign_report(
    report_id: str,
    body: AssignCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_supervisor),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    if not body.agent_ids:
        raise HTTPException(status_code=400, detail="At least one agent_id is required")

    # Deactivate all previous assignments for this report
    db.query(Assignment).filter(
        Assignment.report_id == report.id,
        Assignment.is_active == True,
    ).update({"is_active": False})

    new_assignments: list[Assignment] = []
    for agent_id in body.agent_ids:
        agent = db.get(User, agent_id)
        if not agent:
            raise HTTPException(status_code=404, detail=f"Agent {agent_id} not found")
        a = Assignment(
            report_id=report.id,
            agent_id=agent.id,
            assigned_by=current_user.id,
            note=body.note,
            is_active=True,
        )
        db.add(a)
        new_assignments.append(a)

    # Keep assigned_to pointing to the first agent (backward compat / field_agent filter)
    first_agent = db.get(User, body.agent_ids[0])
    report.assigned_to = first_agent.id

    db.commit()
    for a in new_assignments:
        db.refresh(a)

    publish_report_event("report_assigned", {
        "id": str(report.id),
        "tracking_code": report.tracking_code,
        "agent_ids": body.agent_ids,
        "assigned_by": str(current_user.id),
    })

    return [_assignment_to_out(a) for a in new_assignments]


@router.get("/{report_id}/assignments", response_model=list[AssignmentOut])
def get_assignments(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    assignments = (
        db.query(Assignment)
        .filter(Assignment.report_id == report.id)
        .order_by(Assignment.created_at.desc())
        .all()
    )
    return [_assignment_to_out(a) for a in assignments]


@router.post("/{report_id}/resolution-report", response_model=ResolutionReportOut, status_code=status.HTTP_201_CREATED)
def create_resolution_report(
    report_id: str,
    body: ResolutionReportCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if report.status != ReportStatus.RESOLVED:
        raise HTTPException(status_code=400, detail="Resolution report requires status RESOLVED")
    existing = db.query(ResolutionReport).filter(ResolutionReport.report_id == report.id).first()
    if existing:
        raise HTTPException(status_code=409, detail="Resolution report already exists for this report")

    rr = ResolutionReport(
        report_id=report.id,
        resolved_by=current_user.id,
        comment=body.comment,
        materials=body.materials,
        photo_url=body.photo_url,
    )
    db.add(rr)
    db.commit()
    db.refresh(rr)

    return _resolution_to_out(rr)


@router.get("/{report_id}/resolution-report", response_model=ResolutionReportOut)
def get_resolution_report(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    rr = db.query(ResolutionReport).filter(ResolutionReport.report_id == report.id).first()
    if not rr:
        raise HTTPException(status_code=404, detail="No resolution report for this report")
    return _resolution_to_out(rr)


@router.get("/{report_id}/history", response_model=list)
def get_status_history(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    report = db.get(Report, report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    if current_user.role == UserRole.citizen and report.citizen_id != current_user.id:
        raise HTTPException(status_code=403, detail="Access denied")
    history = (
        db.query(ReportStatusHistory)
        .filter(ReportStatusHistory.report_id == report.id)
        .order_by(ReportStatusHistory.created_at)
        .all()
    )
    return [
        {
            "id": str(h.id),
            "from_status": h.from_status.value if h.from_status else None,
            "to_status": h.to_status.value,
            "note": h.note,
            "changed_by": str(h.changed_by),
            "changed_by_name": h.changed_by_user.full_name if h.changed_by_user else None,
            "created_at": h.created_at.isoformat(),
        }
        for h in history
    ]
