from pydantic import BaseModel, field_validator
from uuid import UUID
from datetime import datetime
from typing import Any
from app.models.report import ReportStatus, ReportPriority


class LocationIn(BaseModel):
    lat: float
    lng: float


class ReportCreate(BaseModel):
    category_id: int
    title: str
    description: str | None = None
    lat: float
    lng: float
    address: str | None = None
    city: str | None = None
    ward: str | None = None
    photo_url: str | None = None
    thumbnail_url: str | None = None

    @field_validator("description")
    @classmethod
    def limit_description(cls, v):
        if v and len(v) > 500:
            raise ValueError("Description must be 500 characters or fewer")
        return v


class StatusUpdate(BaseModel):
    status: ReportStatus
    note: str | None = None


class CommentCreate(BaseModel):
    body: str
    is_public: bool = True


class StatusHistoryOut(BaseModel):
    id: UUID
    from_status: ReportStatus | None
    to_status: ReportStatus
    note: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ReportOut(BaseModel):
    id: UUID
    tracking_code: str
    citizen_id: UUID
    category_id: int
    status: ReportStatus
    priority: ReportPriority
    title: str
    description: str | None
    photo_url: str | None
    thumbnail_url: str | None
    address: str | None
    city: str | None
    ward: str | None
    lat: float | None = None
    lng: float | None = None
    assigned_to: UUID | None
    department_id: int | None
    ai_category_id: int | None
    ai_confidence: float | None
    is_duplicate: bool
    duplicate_of: UUID | None
    resolved_at: datetime | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class ReportListOut(BaseModel):
    items: list[ReportOut]
    total: int
    page: int
    page_size: int


class PresignedUrlRequest(BaseModel):
    filename: str
    content_type: str


class PresignedUrlResponse(BaseModel):
    upload_url: str
    photo_url: str
    thumbnail_url: str
