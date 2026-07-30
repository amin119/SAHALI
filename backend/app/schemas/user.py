from pydantic import BaseModel, EmailStr, field_validator
from uuid import UUID
from datetime import datetime, time
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
    municipality_id: int | None = None
    password: str
    preferred_language: str = "fr"


class StaffUserUpdate(BaseModel):
    full_name: str | None = None
    role: UserRole | None = None
    is_active: bool | None = None
    municipality_id: int | None = None


class UserListOut(BaseModel):
    items: list[UserOut]
    total: int
    page: int
    page_size: int


class ScheduleSlotIn(BaseModel):
    day_of_week: int  # 0=Monday .. 6=Sunday
    start_time: time
    end_time: time

    @field_validator("day_of_week")
    @classmethod
    def valid_day(cls, v):
        if not 0 <= v <= 6:
            raise ValueError("day_of_week must be between 0 (Monday) and 6 (Sunday)")
        return v

    @field_validator("end_time")
    @classmethod
    def end_after_start(cls, v, info):
        start = info.data.get("start_time")
        if start is not None and v <= start:
            raise ValueError("end_time must be after start_time")
        return v


class ScheduleSlotOut(BaseModel):
    id: int
    day_of_week: int
    start_time: time
    end_time: time

    model_config = {"from_attributes": True}


class AgentStatsOut(BaseModel):
    agent_id: str
    assigned: int
    resolved: int
    in_progress: int


class AgentStatsListOut(BaseModel):
    items: list[AgentStatsOut]
