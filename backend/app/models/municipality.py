from geoalchemy2 import Geometry
from sqlalchemy import Column, Date, Integer, String, Text
from sqlalchemy.orm import relationship

from app.database import Base


class Municipality(Base):
    __tablename__ = "municipalities"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    boundary = Column(Geometry("POLYGON", srid=4326), nullable=True)
    location = Column(Geometry("POINT", srid=4326), nullable=True)
    logo_url = Column(Text, nullable=True)
    subscription_tier = Column(String(50), nullable=True)
    subscription_expires = Column(Date, nullable=True)

    staff = relationship("User", back_populates="municipality")
    departments = relationship("Department", back_populates="municipality")
