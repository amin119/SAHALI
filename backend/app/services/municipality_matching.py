from sqlalchemy import text
from sqlalchemy.orm import Session


def closest_municipality_id(db: Session, lat: float, lng: float) -> int | None:
    """Nearest municipality to (lat, lng) by centroid distance (PostGIS KNN).
    Returns None if no municipality has a location set yet."""
    row = db.execute(text("""
        SELECT id FROM municipalities
        WHERE location IS NOT NULL
        ORDER BY location <-> ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)
        LIMIT 1
    """), {"lat": lat, "lng": lng}).fetchone()
    return row[0] if row else None
