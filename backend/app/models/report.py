import uuid
import enum
from sqlalchemy import (
    Column, String, Boolean, Enum, ForeignKey,
    DateTime, Float, Text, Integer, func
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from app.database import Base


class ReportStatus(str, enum.Enum):
    SUBMITTED   = "submitted"
    RECEIVED    = "received"
    UNDER_REVIEW = "under_review"
    IN_PROGRESS = "in_progress"
    RESOLVED    = "resolved"
    REJECTED    = "rejected"


class ReportPriority(str, enum.Enum):
    low      = "low"
    medium   = "medium"
    high     = "high"
    critical = "critical"


class Report(Base):
    __tablename__ = "reports"

    id             = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tracking_code  = Column(String(10), unique=True, nullable=False)
    citizen_id     = Column(ForeignKey("users.id"), nullable=False)
    category_id    = Column(ForeignKey("categories.id"), nullable=False)
    status         = Column(Enum(ReportStatus, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=ReportStatus.SUBMITTED)
    title          = Column(String(200), nullable=False)
    description    = Column(Text, nullable=True)
    photo_url      = Column(Text, nullable=True)
    thumbnail_url  = Column(Text, nullable=True)
    photo_urls     = Column(JSONB, nullable=True, default=list)
    location       = Column(Geometry("POINT", srid=4326), nullable=False)
    address        = Column(Text, nullable=True)
    city           = Column(String(100), nullable=True)
    ward           = Column(String(100), nullable=True)
    assigned_to    = Column(ForeignKey("users.id"), nullable=True)
    analyzed_by    = Column(ForeignKey("users.id"), nullable=True)
    department_id  = Column(ForeignKey("departments.id"), nullable=True)
    ai_category_id = Column(ForeignKey("categories.id"), nullable=True)
    ai_confidence  = Column(Float, nullable=True)
    is_duplicate   = Column(Boolean, nullable=False, default=False)
    duplicate_of   = Column(ForeignKey("reports.id"), nullable=True)
    priority       = Column(Enum(ReportPriority, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=ReportPriority.medium)
    resolved_at    = Column(DateTime(timezone=True), nullable=True)
    created_at     = Column(DateTime(timezone=True), server_default=func.now())
    updated_at     = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    citizen          = relationship("User", foreign_keys=[citizen_id], back_populates="reports")
    assignee         = relationship("User", foreign_keys=[assigned_to], back_populates="assigned_reports")
    analyzer         = relationship("User", foreign_keys=[analyzed_by])
    category         = relationship("Category", foreign_keys=[category_id], back_populates="reports")
    department       = relationship("Department", back_populates="reports")
    status_history   = relationship("ReportStatusHistory", back_populates="report", order_by="ReportStatusHistory.created_at")
    notifications    = relationship("Notification", back_populates="report")
    assignments      = relationship("Assignment", back_populates="report", order_by="Assignment.created_at")
    resolution_report = relationship("ResolutionReport", back_populates="report", uselist=False)


class ReportStatusHistory(Base):
    __tablename__ = "report_status_history"

    id          = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id   = Column(ForeignKey("reports.id"), nullable=False)
    from_status = Column(Enum(ReportStatus, values_callable=lambda obj: [e.value for e in obj]), nullable=True)
    to_status   = Column(Enum(ReportStatus, values_callable=lambda obj: [e.value for e in obj]), nullable=False)
    changed_by  = Column(ForeignKey("users.id"), nullable=False)
    note        = Column(Text, nullable=True)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())

    report           = relationship("Report", back_populates="status_history")
    changed_by_user  = relationship("User")


class Assignment(Base):
    """One row per agent per report assignment. Multiple agents can be assigned."""
    __tablename__ = "assignments"

    id          = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id   = Column(ForeignKey("reports.id"), nullable=False)
    agent_id    = Column(ForeignKey("users.id"), nullable=False)
    assigned_by = Column(ForeignKey("users.id"), nullable=False)
    note        = Column(Text, nullable=True)
    is_active   = Column(Boolean, nullable=False, default=True)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())

    report   = relationship("Report", back_populates="assignments")
    agent    = relationship("User", foreign_keys=[agent_id])
    assigner = relationship("User", foreign_keys=[assigned_by])


class ResolutionReport(Base):
    """Filled by the agent when closing a report as resolved."""
    __tablename__ = "resolution_reports"

    id          = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id   = Column(ForeignKey("reports.id"), nullable=False, unique=True)
    resolved_by = Column(ForeignKey("users.id"), nullable=False)
    comment     = Column(Text, nullable=False)
    materials   = Column(Text, nullable=True)
    photo_url   = Column(Text, nullable=True)
    created_at  = Column(DateTime(timezone=True), server_default=func.now())

    report   = relationship("Report", back_populates="resolution_report")
    resolver = relationship("User", foreign_keys=[resolved_by])
