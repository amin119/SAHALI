from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.category import Category
from app.schemas.category import CategoryOut
from app.utils.deps import require_staff

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
    _=Depends(require_staff),
):
    """Staff-only — flip is_active on a root or child category."""
    cat = db.get(Category, category_id)
    if not cat:
        raise HTTPException(status_code=404, detail="Category not found")
    cat.is_active = not cat.is_active
    db.commit()
    db.refresh(cat)
    return cat
