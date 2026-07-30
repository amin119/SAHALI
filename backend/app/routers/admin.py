from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import func, text, or_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from typing import Annotated
import csv
import io
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
from geoalchemy2.functions import ST_MakePoint, ST_SetSRID

from app.database import get_db
from app.models.report import Report, ReportStatus
from app.models.user import User, UserRole
from app.models.municipality import Municipality
from app.models.agent_schedule import AgentSchedule
from app.schemas.user import (
    StaffUserCreate, StaffUserUpdate, UserOut, UserListOut, ScheduleSlotIn, ScheduleSlotOut,
    AgentStatsOut, AgentStatsListOut,
)
from app.schemas.municipality import (
    MunicipalityOut, MunicipalityListOut, MunicipalityCreate, MunicipalityUpdate,
)
from app.schemas.notification import BroadcastRequest
from app.services import backfill as backfill_service
from app.utils.deps import require_admin, require_staff, require_super_admin
from app.utils.pagination import PaginationParams
from app.utils.security import hash_password

router = APIRouter(prefix="/admin", tags=["admin"])

TUNIS_TZ = ZoneInfo("Africa/Tunis")


def _municipality_query_page(db: Session, pagination: "PaginationParams", search: str | None):
    """Shared aggregate query behind both the list endpoint and the count
    used for pagination — keeps the report/agent-count columns the
    dashboard already relies on, just adds a name search + LIMIT/OFFSET."""
    where_clause = ""
    params: dict = {"limit": pagination.page_size, "offset": pagination.offset}
    if search:
        where_clause = "WHERE m.name ILIKE :search"
        params["search"] = f"%{search}%"

    total = db.execute(
        text(f"SELECT COUNT(*) FROM municipalities m {where_clause}"), params
    ).scalar() or 0

    rows = db.execute(text(f"""
        SELECT
            m.id, m.name, m.subscription_tier,
            COUNT(DISTINCT r.id)                                         AS total_reports,
            COUNT(DISTINCT CASE WHEN r.status = 'resolved' THEN r.id END) AS resolved_reports,
            COUNT(DISTINCT CASE WHEN r.status NOT IN ('resolved','rejected') THEN r.id END) AS open_reports,
            COUNT(DISTINCT u.id) FILTER (WHERE u.role = 'field_agent')  AS agent_count,
            ST_Y(m.location) AS lat, ST_X(m.location) AS lng
        FROM municipalities m
        LEFT JOIN reports r ON r.municipality_id = m.id
        LEFT JOIN users u   ON u.municipality_id = m.id
        {where_clause}
        GROUP BY m.id, m.name, m.subscription_tier, m.location
        ORDER BY m.name
        LIMIT :limit OFFSET :offset
    """), params).fetchall()

    return [_municipality_row_to_dict(r) for r in rows], total


def _municipality_row_to_dict(r) -> dict:
    return {
        "id": r[0], "name": r[1], "subscription_tier": r[2],
        "total_reports": r[3], "resolved_reports": r[4],
        "open_reports": r[5], "agent_count": r[6],
        "resolution_rate": round(r[4] / r[3] * 100) if r[3] > 0 else 0,
        "lat": r[7], "lng": r[8],
    }


def _municipality_stats_by_id(db: Session, municipality_id: int) -> dict | None:
    row = db.execute(text("""
        SELECT
            m.id, m.name, m.subscription_tier,
            COUNT(DISTINCT r.id)                                         AS total_reports,
            COUNT(DISTINCT CASE WHEN r.status = 'resolved' THEN r.id END) AS resolved_reports,
            COUNT(DISTINCT CASE WHEN r.status NOT IN ('resolved','rejected') THEN r.id END) AS open_reports,
            COUNT(DISTINCT u.id) FILTER (WHERE u.role = 'field_agent')  AS agent_count,
            ST_Y(m.location) AS lat, ST_X(m.location) AS lng
        FROM municipalities m
        LEFT JOIN reports r ON r.municipality_id = m.id
        LEFT JOIN users u   ON u.municipality_id = m.id
        WHERE m.id = :id
        GROUP BY m.id, m.name, m.subscription_tier, m.location
    """), {"id": municipality_id}).fetchone()
    return _municipality_row_to_dict(row) if row else None


@router.get("/storage/test")
def test_storage(_: User = Depends(require_super_admin)):
    """Checks storage connectivity without uploading anything — gated to
    super-admin; failures go to server logs, not the response, so the bucket
    name and internal error text can't leak to a caller."""
    import httpx
    import structlog
    from app.config import get_settings
    log = structlog.get_logger()
    s = get_settings()

    if s.SUPABASE_URL and s.SUPABASE_SERVICE_KEY:
        try:
            from urllib.parse import quote
            bucket = quote(s.AWS_S3_BUCKET, safe="")
            url = f"{s.SUPABASE_URL}/storage/v1/bucket/{bucket}"
            resp = httpx.get(url, headers={"Authorization": f"Bearer {s.SUPABASE_SERVICE_KEY}"}, timeout=10)
            if resp.status_code == 200:
                return {"status": "ok", "method": "supabase-rest"}
            log.warning("storage_test_failed", method="supabase-rest", http_status=resp.status_code)
            return {"status": "error", "method": "supabase-rest"}
        except Exception as e:
            log.warning("storage_test_failed", method="supabase-rest", error=str(e))
            return {"status": "error", "method": "supabase-rest"}

    from app.services.storage import _s3_client
    try:
        _s3_client().list_objects_v2(Bucket=s.AWS_S3_BUCKET, MaxKeys=1)
        return {"status": "ok", "method": "s3"}
    except Exception as e:
        log.warning("storage_test_failed", method="s3", error=str(e))
        return {"status": "error", "method": "s3"}


@router.get("/stats/public")
def public_stats(db: Session = Depends(get_db)):
    total = db.query(func.count(Report.id)).scalar() or 0
    by_status = dict(
        db.query(Report.status, func.count(Report.id)).group_by(Report.status).all()
    )
    resolved = by_status.get(ReportStatus.RESOLVED, 0)
    rejected = by_status.get(ReportStatus.REJECTED, 0)
    active = max(total - resolved - rejected, 0)
    return {"total": total, "resolved": resolved, "active": active}


@router.get("/stats")
def dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    today = datetime.now(timezone.utc).date()
    base = db.query(Report)
    if current_user.municipality_id is not None:
        base = base.filter(Report.municipality_id == current_user.municipality_id)

    total = base.with_entities(func.count(Report.id)).scalar()
    today_count = base.filter(func.date(Report.created_at) == today).with_entities(func.count(Report.id)).scalar()
    by_status = (
        base.with_entities(Report.status, func.count(Report.id))
        .group_by(Report.status)
        .all()
    )
    avg_resolution = base.filter(Report.resolved_at.isnot(None)).with_entities(
        func.avg(func.extract("epoch", Report.resolved_at - Report.created_at) / 3600)
    ).scalar()

    return {
        "total_reports": total,
        "today_reports": today_count,
        "by_status": {s.value: c for s, c in by_status},
        "avg_resolution_hours": round(avg_resolution or 0, 1),
    }


@router.get("/reports/export")
def export_reports(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
    city: str | None = Query(None),
    report_status: ReportStatus | None = Query(None, alias="status"),
):
    query = db.query(Report)
    if current_user.municipality_id is not None:
        query = query.filter(Report.municipality_id == current_user.municipality_id)
    if city:
        query = query.filter(Report.city.ilike(f"%{city}%"))
    if report_status:
        query = query.filter(Report.status == report_status)

    reports = query.order_by(Report.created_at.desc()).limit(10000).all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["tracking_code", "status", "priority", "category_id", "city", "address", "created_at", "resolved_at"])
    for r in reports:
        writer.writerow([r.tracking_code, r.status.value, r.priority.value, r.category_id, r.city, r.address, r.created_at, r.resolved_at])

    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=reports.csv"},
    )


@router.get("/agents/stats", response_model=AgentStatsListOut)
def agent_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
):
    """Per-agent assigned/resolved/in-progress counts, aggregated in SQL — the
    Teams page used to fetch up to 500 full report rows (every field,
    including description/photos/AI metadata) just to compute these three
    numbers per agent in the browser. One GROUP BY does the same job."""
    where_clause = "WHERE r.assigned_to IS NOT NULL"
    params: dict = {}
    if current_user.municipality_id is not None:
        where_clause += " AND r.municipality_id = :municipality_id"
        params["municipality_id"] = current_user.municipality_id

    rows = db.execute(text(f"""
        SELECT
            r.assigned_to,
            COUNT(*)                                         AS assigned,
            COUNT(*) FILTER (WHERE r.status = 'resolved')     AS resolved,
            COUNT(*) FILTER (WHERE r.status = 'in_progress')  AS in_progress
        FROM reports r
        {where_clause}
        GROUP BY r.assigned_to
    """), params).fetchall()

    return {"items": [
        AgentStatsOut(agent_id=str(r[0]), assigned=r[1], resolved=r[2], in_progress=r[3])
        for r in rows
    ]}


@router.get("/users", response_model=UserListOut)
def list_staff(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff),
    pagination: Annotated[PaginationParams, Depends()] = None,
    search: str | None = Query(None, description="Match against full name or email"),
    role: UserRole | None = Query(None),
    municipality_id: int | None = Query(None),
    on_shift_now: bool = Query(False, description="Only staff with a schedule slot covering the current moment (Tunis time)"),
):
    query = db.query(User).filter(User.role != UserRole.citizen)
    if search:
        like = f"%{search}%"
        query = query.filter(or_(User.full_name.ilike(like), User.email.ilike(like)))
    if role:
        query = query.filter(User.role == role)
    if current_user.municipality_id is not None:
        query = query.filter(User.municipality_id == current_user.municipality_id)
    elif municipality_id:
        query = query.filter(User.municipality_id == municipality_id)
    if on_shift_now:
        now = datetime.now(TUNIS_TZ)
        query = query.join(AgentSchedule, AgentSchedule.agent_id == User.id).filter(
            AgentSchedule.day_of_week == now.weekday(),
            AgentSchedule.start_time <= now.time(),
            AgentSchedule.end_time > now.time(),
        )

    total = query.count()
    items = (
        query.order_by(User.full_name)
        .offset(pagination.offset)
        .limit(pagination.page_size)
        .all()
    )
    return {"items": items, "total": total, "page": pagination.page, "page_size": pagination.page_size}


@router.post("/users", response_model=UserOut, status_code=201)
def create_staff(
    body: StaffUserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    if db.query(User).filter(User.email == body.email).first():
        raise HTTPException(status_code=409, detail="Email already used")

    municipality_id = body.municipality_id
    if current_user.municipality_id is not None:
        if body.role == UserRole.admin:
            raise HTTPException(status_code=403, detail="Only a super-admin can create admin accounts")
        municipality_id = current_user.municipality_id

    user = User(
        full_name=body.full_name,
        email=body.email,
        phone=body.phone,
        role=body.role,
        municipality_id=municipality_id,
        password_hash=hash_password(body.password),
        preferred_language=body.preferred_language,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.patch("/users/{user_id}", response_model=UserOut)
def update_staff(
    user_id: str,
    body: StaffUserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    scoped = current_user.municipality_id is not None
    if scoped and user.municipality_id != current_user.municipality_id:
        raise HTTPException(status_code=404, detail="User not found")
    if scoped and body.role == UserRole.admin:
        raise HTTPException(status_code=403, detail="Only a super-admin can create admin accounts")
    if scoped and "municipality_id" in body.model_fields_set:
        raise HTTPException(status_code=403, detail="Only a super-admin can change a user's municipality")

    if body.full_name is not None:
        user.full_name = body.full_name
    if body.role is not None:
        user.role = body.role
    if body.is_active is not None:
        user.is_active = body.is_active
    if "municipality_id" in body.model_fields_set:
        user.municipality_id = body.municipality_id
    db.commit()
    db.refresh(user)
    return user


@router.delete("/users/{user_id}", status_code=204)
def delete_staff(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if current_user.municipality_id is not None and user.municipality_id != current_user.municipality_id:
        raise HTTPException(status_code=404, detail="User not found")
    try:
        db.delete(user)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="This agent has historical activity (reports, notifications, or status changes) and can't be permanently deleted. Deactivate the account instead.",
        )


def _get_scoped_staff_or_404(user_id: str, db: Session, current_user: User) -> User:
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if current_user.municipality_id is not None and user.municipality_id != current_user.municipality_id:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.get("/users/{user_id}/schedule", response_model=list[ScheduleSlotOut])
def get_agent_schedule(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    _get_scoped_staff_or_404(user_id, db, current_user)
    return (
        db.query(AgentSchedule)
        .filter(AgentSchedule.agent_id == user_id)
        .order_by(AgentSchedule.day_of_week)
        .all()
    )


@router.put("/users/{user_id}/schedule", response_model=list[ScheduleSlotOut])
def set_agent_schedule(
    user_id: str,
    body: list[ScheduleSlotIn],
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Replaces the agent's whole week in one call — simpler for the caller
    than per-day CRUD, and a schedule is small enough that this is cheap."""
    _get_scoped_staff_or_404(user_id, db, current_user)

    days = [slot.day_of_week for slot in body]
    if len(days) != len(set(days)):
        raise HTTPException(status_code=400, detail="Duplicate day_of_week in schedule")

    db.query(AgentSchedule).filter(AgentSchedule.agent_id == user_id).delete()
    new_slots = [
        AgentSchedule(agent_id=user_id, day_of_week=slot.day_of_week, start_time=slot.start_time, end_time=slot.end_time)
        for slot in body
    ]
    db.add_all(new_slots)
    db.commit()
    for s in new_slots:
        db.refresh(s)
    return new_slots


@router.get("/municipalities", response_model=MunicipalityListOut)
def list_municipalities(
    db: Session = Depends(get_db),
    _: User = Depends(require_super_admin),
    pagination: Annotated[PaginationParams, Depends()] = None,
    search: str | None = Query(None, description="Match against municipality name"),
):
    items, total = _municipality_query_page(db, pagination, search)
    return {"items": items, "total": total, "page": pagination.page, "page_size": pagination.page_size}


@router.post("/municipalities", response_model=MunicipalityOut, status_code=201)
def create_municipality(
    body: MunicipalityCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_super_admin),
):
    if db.query(Municipality).filter(Municipality.name == body.name).first():
        raise HTTPException(status_code=409, detail="A municipality with this name already exists")
    location = ST_SetSRID(ST_MakePoint(body.lng, body.lat), 4326) if body.lat is not None and body.lng is not None else None
    muni = Municipality(name=body.name, subscription_tier=body.subscription_tier, logo_url=body.logo_url, location=location)
    db.add(muni)
    db.commit()
    db.refresh(muni)
    return {
        "id": muni.id, "name": muni.name, "subscription_tier": muni.subscription_tier,
        "total_reports": 0, "resolved_reports": 0, "open_reports": 0,
        "agent_count": 0, "resolution_rate": 0,
        "lat": body.lat, "lng": body.lng,
    }


@router.patch("/municipalities/{municipality_id}", response_model=MunicipalityOut)
def update_municipality(
    municipality_id: int,
    body: MunicipalityUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_super_admin),
):
    muni = db.get(Municipality, municipality_id)
    if not muni:
        raise HTTPException(status_code=404, detail="Municipality not found")
    if body.name is not None:
        existing = db.query(Municipality).filter(Municipality.name == body.name, Municipality.id != municipality_id).first()
        if existing:
            raise HTTPException(status_code=409, detail="A municipality with this name already exists")
        muni.name = body.name
    if body.subscription_tier is not None:
        muni.subscription_tier = body.subscription_tier
    if body.logo_url is not None:
        muni.logo_url = body.logo_url
    if body.lat is not None and body.lng is not None:
        muni.location = ST_SetSRID(ST_MakePoint(body.lng, body.lat), 4326)
    db.commit()

    return _municipality_stats_by_id(db, municipality_id) or {
        "id": muni.id, "name": muni.name, "subscription_tier": muni.subscription_tier,
        "total_reports": 0, "resolved_reports": 0, "open_reports": 0,
        "agent_count": 0, "resolution_rate": 0,
    }


@router.get("/municipalities/{municipality_id}/agents", response_model=list[UserOut])
def list_municipality_agents(
    municipality_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_super_admin),
):
    """Who actually works in this municipality — a super-admin's view across
    the whole platform; a municipal admin already gets this via GET /admin/users,
    which is auto-scoped to their own municipality."""
    if not db.get(Municipality, municipality_id):
        raise HTTPException(status_code=404, detail="Municipality not found")
    return (
        db.query(User)
        .filter(User.municipality_id == municipality_id, User.role != UserRole.citizen)
        .order_by(User.full_name)
        .all()
    )


@router.delete("/municipalities/{municipality_id}", status_code=204)
def delete_municipality(
    municipality_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_super_admin),
):
    muni = db.get(Municipality, municipality_id)
    if not muni:
        raise HTTPException(status_code=404, detail="Municipality not found")
    try:
        db.delete(muni)
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=409,
            detail="This municipality still has agents or departments assigned to it and can't be deleted. Reassign or remove them first.",
        )


@router.post("/notifications/broadcast")
def broadcast(
    body: BroadcastRequest,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    from app.models.notification import Notification
    from app.models.user import UserRole
    query = db.query(User).filter(User.role == UserRole.citizen, User.is_active)
    if body.city:
        query = query.filter(User.municipality_id.isnot(None))  # simplified; extend with city join if needed

    users = query.all()
    for u in users:
        db.add(Notification(user_id=u.id, title=body.title, body=body.body))
    db.commit()
    return {"message": f"Broadcast sent to {len(users)} users"}


# ── One-off backfill triggers ────────────────────────────────────────────
# Run these instead of the equivalent scripts/*.py when Shell access isn't
# available (e.g. Render's free tier). Each runs in the background using the
# server's own DB connection and outbound network access — progress and
# completion show up in the service's Logs tab (structlog "backfill_*" events).

def _run_backfill(fn):
    from app.database import SessionLocal
    with SessionLocal() as db:
        fn(db)


@router.post("/backfill/municipality-coordinates")
def trigger_backfill_municipality_coordinates(
    background: BackgroundTasks,
    _: User = Depends(require_super_admin),
):
    background.add_task(_run_backfill, backfill_service.backfill_municipality_coordinates)
    return {"message": "Started in background — this takes several minutes for ~335 municipalities. Watch the Logs tab for backfill_municipality_coordinates_* events."}


@router.post("/backfill/report-municipality")
def trigger_backfill_report_municipality(
    background: BackgroundTasks,
    _: User = Depends(require_super_admin),
):
    background.add_task(_run_backfill, backfill_service.backfill_report_municipality)
    return {"message": "Started in background. Watch the Logs tab for backfill_report_municipality_* events."}


@router.post("/backfill/report-addresses")
def trigger_backfill_report_addresses(
    background: BackgroundTasks,
    _: User = Depends(require_super_admin),
):
    background.add_task(_run_backfill, backfill_service.backfill_report_addresses)
    return {"message": "Started in background. Watch the Logs tab for backfill_report_addresses_* events."}
