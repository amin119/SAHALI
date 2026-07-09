"""
One-time forward-geocode of every municipality name to a centroid point,
used to auto-route reports to their nearest municipality. Safe to re-run —
only touches rows where location is still null. Respects Nominatim's
1 request/second usage policy (~335 municipalities => ~6 minutes).

Run from the backend directory, with DATABASE_URL pointed at whichever
database you want to update (local or Supabase/prod):
    uv run python scripts/backfill_municipality_coordinates.py
"""
import asyncio
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.models.municipality import Municipality
from app.services.geocoding import forward_geocode


def main():
    db = SessionLocal()
    try:
        municipalities = db.query(Municipality).filter(Municipality.location.is_(None)).all()
        print(f"Found {len(municipalities)} municipalities missing coordinates.")

        updated = 0
        for i, m in enumerate(municipalities, start=1):
            result = asyncio.run(forward_geocode(f"{m.name}, Tunisia"))
            if result:
                lat, lng = result
                m.location = f"SRID=4326;POINT({lng} {lat})"
                db.commit()
                updated += 1
                print(f"  [{i}/{len(municipalities)}] {m.name}: {lat}, {lng}")
            else:
                print(f"  [{i}/{len(municipalities)}] {m.name}: geocoding failed, skipped")
            if i < len(municipalities):
                time.sleep(1.1)  # Nominatim usage policy: max 1 req/sec

        print(f"Done. Updated {updated}/{len(municipalities)} municipalities.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
