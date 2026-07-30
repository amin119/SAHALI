from sqlalchemy import Column, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.database import Base


class Department(Base):
    __tablename__ = "departments"

    id = Column(Integer, primary_key=True, autoincrement=True)
    municipality_id = Column(ForeignKey("municipalities.id"), nullable=False)
    name = Column(String(200), nullable=False)
    email = Column(String(200), nullable=True)

    municipality = relationship("Municipality", back_populates="departments")
    categories = relationship("Category", back_populates="default_department")
    reports = relationship("Report", back_populates="department")
