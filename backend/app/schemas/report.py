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
    photo_urls: list[str] = []

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


class UserBrief(BaseModel):
    id: UUID
    full_name: str
    role: str

    model_config = {"from_attributes": True}


class AssignCreate(BaseModel):
    agent_ids: list[str]
    note: str | None = None


class AssignmentOut(BaseModel):
    id: UUID
    agent: UserBrief
    assigned_by_user: UserBrief
    note: str | None
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class ResolutionReportCreate(BaseModel):
    comment: str
    materials: str | None = None
    photo_url: str | None = None


class ResolutionReportOut(BaseModel):
    id: UUID
    comment: str
    materials: str | None
    photo_url: str | None
    resolved_by_user: UserBrief
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
    photo_urls: list[str] = []
    address: str | None
    city: str | None
    ward: str | None
    lat: float | None = None
    lng: float | None = None
    assigned_to: UUID | None
    analyzed_by: UUID | None = None
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


class PhotoUploadResponse(BaseModel):
    photo_url: str
    thumbnail_url: str
