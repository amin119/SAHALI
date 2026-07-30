from pydantic import BaseModel


class MunicipalityOut(BaseModel):
    id: int
    name: str
    subscription_tier: str | None
    total_reports: int
    resolved_reports: int
    open_reports: int
    agent_count: int
    resolution_rate: int
    lat: float | None = None
    lng: float | None = None


class MunicipalityListOut(BaseModel):
    items: list[MunicipalityOut]
    total: int
    page: int
    page_size: int


class MunicipalityCreate(BaseModel):
    name: str
    subscription_tier: str | None = None
    logo_url: str | None = None
    lat: float | None = None
    lng: float | None = None


class MunicipalityUpdate(BaseModel):
    name: str | None = None
    subscription_tier: str | None = None
    logo_url: str | None = None
    lat: float | None = None
    lng: float | None = None
