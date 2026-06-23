from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import func, text
from sqlalchemy.orm import Session
from typing import Annotated
import csv, io
from datetime import datetime, timezone

from app.database import get_db
from app.models.report import Report, ReportStatus
from app.models.user import User
from app.schemas.user import StaffUserCreate, StaffUserUpdate, UserOut
from app.schemas.notification import BroadcastRequest
from app.utils.deps import require_admin, require_supervisor, require_staff, get_current_user
from app.utils.pagination import PaginationParams
from app.utils.security import hash_password

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/stats")
def dashboard_stats(
    db: Session = Depends(get_db),
    _: User = Depends(require_staff),
):
    today = datetime.now(timezone.utc).date()
    total = db.query(func.count(Report.id)).scalar()
    today_count = db.query(func.count(Report.id)).filter(func.date(Report.created_at) == today).scalar()
    by_status = (
        db.query(Report.status, func.count(Report.id))
        .group_by(Report.status)
        .all()
    )
    resolved = db.query(Report).filter(Report.resolved_at.isnot(None))
    avg_resolution = db.query(
        func.avg(func.extract("epoch", Report.resolved_at - Report.created_at) / 3600)
    ).filter(Report.resolved_at.isnot(None)).scalar()

    return {
        "total_reports": total,
        "today_reports": today_count,
        "by_status": {s.value: c for s, c in by_status},
        "avg_resolution_hours": round(avg_resolution or 0, 1),
    }


@router.get("/reports/export")
def export_reports(
    db: Session = Depends(get_db),
    _: User = Depends(require_supervisor),
    city: str | None = Query(None),
    report_status: ReportStatus | None = Query(None, alias="status"),
):
    query = db.query(Report)
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


@router.get("/users", response_model=list[UserOut])
def list_staff(
    db: Session = Depends(get_db),
    _: User = Depends(require_staff),
    pagination: Annotated[PaginationParams, Depends()] = None,
):
    from app.models.user import UserRole
    return (
        db.query(User)
        .filter(User.role != UserRole.citizen)
        .offset(pagination.offset if pagination else 0)
        .limit(pagination.page_size if pagination else 50)
        .all()
    )


@router.post("/users", response_model=UserOut, status_code=201)
def create_staff(
    body: StaffUserCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    if db.query(User).filter(User.email == body.email).first():
        raise HTTPException(status_code=409, detail="Email already used")
    user = User(
        full_name=body.full_name,
        email=body.email,
        phone=body.phone,
        role=body.role,
        municipality_id=body.municipality_id,
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
    _: User = Depends(require_admin),
):
    user = db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if body.full_name is not None:
        user.full_name = body.full_name
    if body.role is not None:
        user.role = body.role
    if body.is_active is not None:
        user.is_active = body.is_active
    if body.municipality_id is not None:
        user.municipality_id = body.municipality_id
    db.commit()
    db.refresh(user)
    return user


@router.get("/municipalities")
def list_municipalities(db: Session = Depends(get_db), _: User = Depends(require_staff)):
    rows = db.execute(text("""
        SELECT
            m.id, m.name, m.subscription_tier,
            COUNT(DISTINCT r.id)                                         AS total_reports,
            COUNT(DISTINCT CASE WHEN r.status IN ('resolved','closed') THEN r.id END) AS resolved_reports,
            COUNT(DISTINCT CASE WHEN r.status NOT IN ('resolved','closed','rejected') THEN r.id END) AS open_reports,
            COUNT(DISTINCT u.id) FILTER (WHERE u.role = 'field_agent')  AS agent_count
        FROM municipalities m
        LEFT JOIN reports r ON r.city ILIKE '%' || m.name || '%'
        LEFT JOIN users u   ON u.municipality_id = m.id
        GROUP BY m.id, m.name, m.subscription_tier
        ORDER BY total_reports DESC
    """)).fetchall()
    return [
        {
            "id": r[0], "name": r[1], "subscription_tier": r[2],
            "total_reports": r[3], "resolved_reports": r[4],
            "open_reports": r[5], "agent_count": r[6],
            "resolution_rate": round(r[4] / r[3] * 100) if r[3] > 0 else 0,
        }
        for r in rows
    ]


@router.post("/notifications/broadcast")
def broadcast(
    body: BroadcastRequest,
    db: Session = Depends(get_db),
    _: User = Depends(require_supervisor),
):
    from app.models.notification import Notification
    from app.models.user import UserRole
    query = db.query(User).filter(User.role == UserRole.citizen, User.is_active == True)
    if body.city:
        query = query.filter(User.municipality_id.isnot(None))  # simplified; extend with city join if needed

    users = query.all()
    for u in users:
        db.add(Notification(user_id=u.id, title=body.title, body=body.body))
    db.commit()
    return {"message": f"Broadcast sent to {len(users)} users"}
