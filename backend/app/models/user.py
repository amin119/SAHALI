import uuid
import enum
from sqlalchemy import Column, String, Boolean, Enum, ForeignKey, DateTime, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class UserRole(str, enum.Enum):
    citizen = "citizen"
    supervisor = "supervisor"
    field_agent = "field_agent"
    analyst = "analyst"
    admin = "admin"


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role = Column(Enum(UserRole, values_callable=lambda obj: [e.value for e in obj]), nullable=False, default=UserRole.citizen)
    full_name = Column(String(200), nullable=False)
    phone = Column(String(20), unique=True, nullable=True)
    email = Column(String(200), unique=True, nullable=True)
    password_hash = Column(String, nullable=True)
    municipality_id = Column(ForeignKey("municipalities.id"), nullable=True)
    fcm_token = Column(String, nullable=True)
    preferred_language = Column(String(2), nullable=False, default="fr")
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    municipality = relationship("Municipality", back_populates="staff")
    reports = relationship("Report", foreign_keys="Report.citizen_id", back_populates="citizen")
    assigned_reports = relationship("Report", foreign_keys="Report.assigned_to", back_populates="assignee")
    notifications = relationship("Notification", back_populates="user")
