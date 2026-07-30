from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class NotificationOut(BaseModel):
    id: UUID
    report_id: UUID | None
    title: str
    body: str
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class BroadcastRequest(BaseModel):
    title: str
    body: str
    city: str | None = None
    lat: float | None = None
    lng: float | None = None
    radius_meters: float | None = None
