from sqlalchemy import Column, Integer, String, Date, Text
from sqlalchemy.orm import relationship
from geoalchemy2 import Geometry
from app.database import Base


class Municipality(Base):
    __tablename__ = "municipalities"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    boundary = Column(Geometry("POLYGON", srid=4326), nullable=True)
    logo_url = Column(Text, nullable=True)
    subscription_tier = Column(String(50), nullable=True)
    subscription_expires = Column(Date, nullable=True)

    staff = relationship("User", back_populates="municipality")
    departments = relationship("Department", back_populates="municipality")
