"""
Assigns the nearest municipality to existing reports that don't have one yet,
using their stored lat/lng. Requires municipalities to already have
coordinates (run backfill_municipality_coordinates.py first). Safe to re-run.

Run from the backend directory, with DATABASE_URL pointed at whichever
database you want to update (local or Supabase/prod):
    uv run python scripts/backfill_report_municipality.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from geoalchemy2.shape import to_shape

from app.database import SessionLocal
from app.models.report import Report
from app.services.municipality_matching import closest_municipality_id


def main():
    db = SessionLocal()
    try:
        reports = (
            db.query(Report)
            .filter(Report.municipality_id.is_(None))
            .filter(Report.location.isnot(None))
            .all()
        )
        print(f"Found {len(reports)} reports missing a municipality.")

        updated = 0
        for i, report in enumerate(reports, start=1):
            point = to_shape(report.location)
            lat, lng = point.y, point.x
            municipality_id = closest_municipality_id(db, lat, lng)
            if municipality_id:
                report.municipality_id = municipality_id
                db.commit()
                updated += 1
                print(f"  [{i}/{len(reports)}] {report.tracking_code}: municipality_id={municipality_id}")
            else:
                print(f"  [{i}/{len(reports)}] {report.tracking_code}: no municipality with coordinates yet, skipped")

        print(f"Done. Updated {updated}/{len(reports)} reports.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
