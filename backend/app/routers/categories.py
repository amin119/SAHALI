from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.category import Category, MunicipalityCategory
from app.models.municipality import Municipality
from app.models.user import User
from app.schemas.category import CategoryOut, CategoryUpdate, MunicipalityCategoryOut, MunicipalityCategoryToggle
from app.utils.deps import require_staff, require_super_admin, require_admin
from app.services.municipality_matching import closest_municipality_id

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
def list_categories(
    db: Session = Depends(get_db),
    municipality_id: int | None = Query(None, description="Filter out categories disabled for this municipality"),
    lat: float | None = Query(None, description="Used with lng to auto-resolve the nearest municipality"),
    lng: float | None = Query(None),
):
    """Public — returns active root categories (with their children).
    A municipality (given directly, or resolved from lat/lng) additionally
    excludes anything its own admin has disabled locally."""
    resolved_muni_id = municipality_id
    if resolved_muni_id is None and lat is not None and lng is not None:
        resolved_muni_id = closest_municipality_id(db, lat, lng)

    query = db.query(Category).filter(Category.parent_id.is_(None), Category.is_active)

    if resolved_muni_id is not None:
        disabled_ids = {
            row.category_id for row in db.query(MunicipalityCategory).filter(
                MunicipalityCategory.municipality_id == resolved_muni_id,
                MunicipalityCategory.is_active.is_(False),
            )
        }
        if disabled_ids:
            return [
                CategoryOut(
                    id=c.id, parent_id=c.parent_id, slug=c.slug,
                    label_ar=c.label_ar, label_fr=c.label_fr, label_en=c.label_en,
                    default_department_id=c.default_department_id, icon=c.icon,
                    sla_hours=c.sla_hours, is_active=c.is_active,
                    children=[CategoryOut.model_validate(child) for child in c.children if child.id not in disabled_ids],
                )
                for c in query.all() if c.id not in disabled_ids
            ]

    return query.all()


@router.get("/all", response_model=list[CategoryOut])
def list_all_categories(db: Session = Depends(get_db), _=Depends(require_staff)):
    """Staff-only — returns all root categories including inactive ones."""
    roots = db.query(Category).filter(Category.parent_id.is_(None)).all()
    return roots


@router.patch("/{category_id}/toggle", response_model=CategoryOut)
def toggle_category(
    category_id: int,
    db: Session = Depends(get_db),
    _=Depends(require_super_admin),
):
    """Super-admin-only — flip is_active on a root or child category.
    This is shared, platform-wide taxonomy, so a municipal admin toggling it
    would silently affect every other municipality too."""
    cat = db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    cat.is_active = not cat.is_active
    db.commit()
    db.refresh(cat)
    return cat


@router.patch("/{category_id}", response_model=CategoryOut)
def update_category(
    category_id: int,
    body: CategoryUpdate,
    db: Session = Depends(get_db),
    _=Depends(require_super_admin),
):
    """Super-admin-only — update a category's SLA target (in hours).
    Shared, platform-wide config — see toggle_category's docstring."""
    cat = db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    if body.sla_hours is not None:
        if body.sla_hours <= 0:
            raise HTTPException(status_code=400, detail="SLA hours must be positive")
        cat.sla_hours = body.sla_hours
    db.commit()
    db.refresh(cat)
    return cat


def _require_own_municipality_or_super_admin(municipality_id: int, current_user: User, db: Session) -> Municipality:
    muni = db.get(Municipality, municipality_id)
    if not muni:
        raise HTTPException(status_code=404, detail="Municipality not found")
    if current_user.municipality_id is not None and current_user.municipality_id != municipality_id:
        raise HTTPException(status_code=404, detail="Municipality not found")
    return muni


@router.get("/municipality/{municipality_id}", response_model=list[MunicipalityCategoryOut])
def list_categories_for_municipality(
    municipality_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Municipal-admin view: every globally-active category, annotated with
    whether it's active for THIS municipality specifically. A super-admin can
    inspect any municipality; a municipal admin only their own."""
    _require_own_municipality_or_super_admin(municipality_id, current_user, db)

    overrides = {
        row.category_id: row.is_active
        for row in db.query(MunicipalityCategory).filter(MunicipalityCategory.municipality_id == municipality_id)
    }

    def to_out(cat: Category) -> MunicipalityCategoryOut:
        return MunicipalityCategoryOut(
            id=cat.id, slug=cat.slug, label_ar=cat.label_ar, label_fr=cat.label_fr, label_en=cat.label_en,
            icon=cat.icon, globally_active=cat.is_active,
            active_for_municipality=overrides.get(cat.id, True),
            children=[to_out(child) for child in cat.children],
        )

    roots = db.query(Category).filter(Category.parent_id.is_(None)).order_by(Category.id).all()
    return [to_out(c) for c in roots]


@router.put("/municipality/{municipality_id}/{category_id}", response_model=MunicipalityCategoryOut)
def set_category_for_municipality(
    municipality_id: int,
    category_id: int,
    body: MunicipalityCategoryToggle,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    """Municipal-admin-only-for-their-own (or super-admin for any): enable or
    disable one category for this municipality's citizens, without touching
    the platform-wide setting other municipalities see."""
    _require_own_municipality_or_super_admin(municipality_id, current_user, db)
    cat = db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")

    override = db.query(MunicipalityCategory).filter(
        MunicipalityCategory.municipality_id == municipality_id,
        MunicipalityCategory.category_id == category_id,
    ).first()
    if override:
        override.is_active = body.is_active
    else:
        override = MunicipalityCategory(municipality_id=municipality_id, category_id=category_id, is_active=body.is_active)
        db.add(override)
    db.commit()

    return MunicipalityCategoryOut(
        id=cat.id, slug=cat.slug, label_ar=cat.label_ar, label_fr=cat.label_fr, label_en=cat.label_en,
        icon=cat.icon, globally_active=cat.is_active, active_for_municipality=body.is_active,
        children=[],
    )
