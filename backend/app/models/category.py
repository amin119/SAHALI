from sqlalchemy import Column, Integer, String, ForeignKey
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
    default_department_id = Column(ForeignKey("departments.id"), nullable=True)
    icon = Column(String(50), nullable=True)
    sla_hours = Column(Integer, nullable=True)

    parent = relationship("Category", remote_side=[id], back_populates="children")
    children = relationship("Category", back_populates="parent")
    default_department = relationship("Department", back_populates="categories")
    reports = relationship("Report", foreign_keys="Report.category_id", back_populates="category")
