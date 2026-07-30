from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import relationship

from app.database import Base


class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, autoincrement=True)
    parent_id = Column(ForeignKey("categories.id"), nullable=True)
    slug = Column(String(100), unique=True, nullable=False)
    label_ar = Column(String(200), nullable=False)
    label_fr = Column(String(200), nullable=False)
    label_en = Column(String(200), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True, server_default="true")
    default_department_id = Column(ForeignKey("departments.id"), nullable=True)
    icon = Column(String(50), nullable=True)
    sla_hours = Column(Integer, nullable=True)

    parent = relationship("Category", remote_side=[id], back_populates="children")
    children = relationship("Category", back_populates="parent")
    default_department = relationship("Department", back_populates="categories")
    reports = relationship("Report", foreign_keys="Report.category_id", back_populates="category")


class MunicipalityCategory(Base):
    """Per-municipality override of a category's visibility. Absence of a row
    means "active" (inherits the category's own global is_active) — so every
    municipality that has never touched this feature keeps seeing everything
    the super-admin has enabled platform-wide, with zero migration needed."""
    __tablename__ = "municipality_categories"

    id = Column(Integer, primary_key=True, autoincrement=True)
    municipality_id = Column(ForeignKey("municipalities.id", ondelete="CASCADE"), nullable=False)
    category_id = Column(ForeignKey("categories.id", ondelete="CASCADE"), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)

    municipality = relationship("Municipality")
    category = relationship("Category")

    __table_args__ = (
        UniqueConstraint("municipality_id", "category_id", name="uq_municipality_category"),
    )
