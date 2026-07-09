from pydantic import BaseModel


class CategoryOut(BaseModel):
    id: int
    parent_id: int | None
    slug: str
    label_ar: str
    label_fr: str
    label_en: str
    default_department_id: int | None
    icon: str | None
    sla_hours: int | None
    is_active: bool = True
    children: list["CategoryOut"] = []

    model_config = {"from_attributes": True}


CategoryOut.model_rebuild()


class CategoryUpdate(BaseModel):
    sla_hours: int | None = None
