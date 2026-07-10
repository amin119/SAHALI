from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.category import Category
from app.schemas.category import CategoryOut, CategoryUpdate
from app.utils.deps import require_staff, require_super_admin

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
def list_categories(db: Session = Depends(get_db)):
    """Public — returns only active root categories (with their children)."""
    roots = (
        db.query(Category)
        .filter(Category.parent_id.is_(None), Category.is_active == True)
        .all()
    )
    return roots


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
