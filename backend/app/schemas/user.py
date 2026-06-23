from pydantic import BaseModel, EmailStr
from uuid import UUID
from datetime import datetime
from app.models.user import UserRole


class UserOut(BaseModel):
    id: UUID
    role: UserRole
    full_name: str
    phone: str | None
    email: str | None
    municipality_id: int | None
    preferred_language: str
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    full_name: str | None = None
    preferred_language: str | None = None
    fcm_token: str | None = None


class StaffUserCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone: str | None = None
    role: UserRole
    municipality_id: int
    password: str
    preferred_language: str = "fr"


class StaffUserUpdate(BaseModel):
    full_name: str | None = None
    role: UserRole | None = None
    is_active: bool | None = None
    municipality_id: int | None = None
