from fastapi import APIRouter, Depends, HTTPException, status, BackgroundTasks, Query, UploadFile, File, Response
from fastapi.responses import StreamingResponse
import io
from sqlalchemy import func, text
from sqlalchemy.orm import Session, joinedload
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
from app.services.geocoding import reverse_geocode
from app.services.municipality_matching import closest_municipality_id
from app.services.event_bus import publish_report_event
from app.utils.retry import with_retries

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


def _check_municipality_access(report: Report, current_user: User, db: Session) -> None:
    """Municipality-scoped admin/supervisor/analyst can only reach reports
    belonging to their own municipality. 404, not 403, so existence in
    another municipality isn't revealed. No-op for super-admins
    (municipality_id is None).

    Field agents are NOT municipality-scoped here — their real access grant
    is an Assignment row, which can legitimately exist even when the
    report's own municipality_id hasn't been backfilled yet (or, in principle,
    differs from the agent's). Comparing municipality_id for them would
    wrongly 404 a report they're genuinely assigned to."""
    if current_user.role == UserRole.field_agent:
        assigned = db.query(Assignment).filter(
            Assignment.report_id == report.id,
            Assignment.agent_id == current_user.id,
            Assignment.is_active == True,
        ).first()
        if not assigned:
            raise HTTPException(status_code=404, detail="Report not found")
        return
    if current_user.municipality_id is not None and report.municipality_id != current_user.municipality_id:
        raise HTTPException(status_code=404, detail="Report not found")


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
        photo_urls=rr.photo_urls or [],
        video_url=rr.video_url,
        voice_note_url=rr.voice_note_url,
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
):
    data = await file.read()
    filename = file.filename or "photo.jpg"
    content_type = file.content_type or "image/jpeg"
    try:
        result = storage_upload_photo(data, filename, content_type)
        return PhotoUploadResponse(**result)
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail="Photo storage unavailable. Submit without photo.",
        )


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
        municipality_id=closest_municipality_id(db, body.lat, body.lng),
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
    background.add_task(_notify, report.id, "SUBMITTED")
    background.add_task(_notify_staff, report.id)
    if not report.address and not report.city:
        background.add_task(_geocode_and_update, report.id, body.lat, body.lng)

    publish_report_event("report_created", {
        "id": str(report.id),
        "tracking_code": report.tracking_code,
        "city": report.city,
        "category_id": report.category_id,
        "status": report.status.value,
        "priority": report.priority.value if report.priority else None,
        "municipality_id": report.municipality_id,
    })

    return _report_to_out(report)


def _get_or_create_anon_user(db: Session) -> User:
    anon = db.query(User).filter(User.email == "anonymous@sahali.tn").first()
    if not anon:
        anon = User(
            full_name="Anonymous Citizen",
            email="anonymous@sahali.tn",
            role=UserRole.citizen,
            is_active=True,
            preferred_language="fr",
            password_hash=None,
        )
        db.add(anon)
        db.commit()
        db.refresh(anon)
    return anon


@router.post("/anonymous", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
def submit_anonymous_report(
    body: ReportCreate,
    background: BackgroundTasks,
    db: Session = Depends(get_db),
):
    anon = _get_or_create_anon_user(db)

    tracking_code = generate_tracking_code()
    while db.query(Report).filter(Report.tracking_code == tracking_code).first():
        tracking_code = generate_tracking_code()

    all_photo_urls = list(body.photo_urls)
    if body.photo_url and body.photo_url not in all_photo_urls:
        all_photo_urls.insert(0, body.photo_url)
    primary_photo = all_photo_urls[0] if all_photo_urls else body.photo_url

    point = f"SRID=4326;POINT({body.lng} {body.lat})"
    report = Report(
        tracking_code=tracking_code,
        citizen_id=anon.id,
        category_id=body.category_id,
        title=body.title,
        description=body.description,
        photo_url=primary_photo,
        thumbnail_url=body.thumbnail_url or primary_photo,
        photo_urls=all_photo_urls,
        location=point,
        address=body.address,
        city=body.city,
        municipality_id=closest_municipality_id(db, body.lat, body.lng),
        ward=body.ward,
    )
    db.add(report)
    db.flush()

    history = ReportStatusHistory(
        report_id=report.id,
        from_status=None,
        to_status=ReportStatus.SUBMITTED,
        changed_by=anon.id,
    )
    db.add(history)
    db.commit()
    db.refresh(report)

    background.add_task(_run_ai_analysis, report.id, body, "fr")
    background.add_task(_notify_staff, report.id)
    if not report.address and not report.city:
        background.add_task(_geocode_and_update, report.id, body.lat, body.lng)

    publish_report_event("report_created", {
        "id": str(report.id),
        "tracking_code": report.tracking_code,
        "city": report.city,
        "category_id": report.category_id,
        "status": report.status.value,
        "priority": report.priority.value if report.priority else None,
        "municipality_id": report.municipality_id,
    })

    return _report_to_out(report)


def _notify(report_id, event: str):
    def _do():
        from app.database import SessionLocal
        with SessionLocal() as db:
            r = db.get(Report, report_id)
            if r:
                notify_citizen(db, r, event)
                db.commit()
    with_retries(_do, task_name="notify_citizen")


def _notify_staff(report_id):
    def _do():
        from app.database import SessionLocal
        with SessionLocal() as db:
            r = db.get(Report, report_id)
            if r:
                notify_staff(db, r)
                db.commit()
    with_retries(_do, task_name="notify_staff")


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
    with_retries(lambda: asyncio.run(_inner()), task_name="ai_analysis")


def _geocode_and_update(report_id, lat: float, lng: float):
    def _do():
        result = asyncio.run(reverse_geocode(lat, lng))
        if result and any(result.values()):
            from app.database import SessionLocal
            with SessionLocal() as sess:
                r = sess.get(Report, report_id)
                if r and not r.address and not r.city:
                    r.address = result.get("address")
                    r.city = result.get("city")
                    r.address_ar = result.get("address_ar")
                    r.city_ar = result.get("city_ar")
                    sess.commit()
    with_retries(_do, task_name="reverse_geocode")


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
        # Admin / supervisor / analyst see ALL reports including submitted,
        # unless scoped to a single municipality (municipal admin/supervisor/analyst)
        if current_user.municipality_id is not None:
            query = query.filter(Report.municipality_id == current_user.municipality_id)
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
    _check_municipality_access(report, current_user, db)
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
    _check_municipality_access(report, current_user, db)

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
        "municipality_id": report.municipality_id,
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
    _check_municipality_access(report, current_user, db)

    if not body.agent_ids:
        raise HTTPException(status_code=400, detail="At least one agent_id is required")

    # Deactivate all previous assignments for this report
    db.query(Assignment).filter(
        Assignment.report_id == report.id,
        Assignment.is_active == True,
    ).update({"is_active": False})

    agent_query = db.query(User).filter(User.id.in_(body.agent_ids))
    if report.municipality_id is not None:
        # Never assign an agent from a different municipality than the
        # report's, regardless of the caller's own scope.
        agent_query = agent_query.filter(User.municipality_id == report.municipality_id)
    agents_by_id = {str(a.id): a for a in agent_query.all()}
    missing = [agent_id for agent_id in body.agent_ids if agent_id not in agents_by_id]
    if missing:
        raise HTTPException(status_code=404, detail=f"Agent(s) not found: {', '.join(missing)}")

    new_assignments: list[Assignment] = []
    for agent_id in body.agent_ids:
        a = Assignment(
            report_id=report.id,
            agent_id=agents_by_id[agent_id].id,
            assigned_by=current_user.id,
            note=body.note,
            is_active=True,
        )
        db.add(a)
        new_assignments.append(a)

    # Keep assigned_to pointing to the first agent (backward compat / field_agent filter)
    report.assigned_to = agents_by_id[body.agent_ids[0]].id

    db.commit()
    for a in new_assignments:
        db.refresh(a)

    publish_report_event("report_assigned", {
        "id": str(report.id),
        "tracking_code": report.tracking_code,
        "agent_ids": body.agent_ids,
        "assigned_by": str(current_user.id),
        "municipality_id": report.municipality_id,
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
    _check_municipality_access(report, current_user, db)
    assignments = (
        db.query(Assignment)
        .options(joinedload(Assignment.agent), joinedload(Assignment.assigner))
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
    _check_municipality_access(report, current_user, db)
    if report.status != ReportStatus.RESOLVED:
        raise HTTPException(status_code=400, detail="Resolution report requires status RESOLVED")
    existing = db.query(ResolutionReport).filter(ResolutionReport.report_id == report.id).first()
    if existing:
        raise HTTPException(status_code=409, detail="Resolution report already exists for this report")
    if not body.photo_urls and not body.video_url:
        raise HTTPException(status_code=400, detail="At least one photo or a video is required as proof")

    rr = ResolutionReport(
        report_id=report.id,
        resolved_by=current_user.id,
        comment=body.comment,
        materials=body.materials,
        photo_url=body.photo_urls[0] if body.photo_urls else body.photo_url,
        photo_urls=body.photo_urls,
        video_url=body.video_url,
        voice_note_url=body.voice_note_url,
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
    _check_municipality_access(report, current_user, db)
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
    _check_municipality_access(report, current_user, db)
    history = (
        db.query(ReportStatusHistory)
        .options(joinedload(ReportStatusHistory.changed_by_user))
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
