"""
Reverse-geocodes existing reports whose address/city are still null, using
their stored lat/lng. Safe to re-run — only touches rows where both fields
are still empty. Respects Nominatim's 1 request/second usage policy.

Run from the backend directory, with DATABASE_URL pointed at whichever
database you want to backfill (local or Supabase/prod):
    uv run python scripts/backfill_report_addresses.py
"""
import asyncio
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from geoalchemy2.shape import to_shape

from app.database import SessionLocal
from app.models.report import Report
from app.services.geocoding import reverse_geocode


def main():
    db = SessionLocal()
    try:
        reports = (
            db.query(Report)
            .filter(Report.address.is_(None), Report.city.is_(None))
            .filter(Report.location.isnot(None))
            .all()
        )
        print(f"Found {len(reports)} reports missing address/city.")

        updated = 0
        for i, report in enumerate(reports, start=1):
            point = to_shape(report.location)
            lat, lng = point.y, point.x
            result = asyncio.run(reverse_geocode(lat, lng))
            if result and any(result.values()):
                report.address = result.get("address")
                report.city = result.get("city")
                report.address_ar = result.get("address_ar")
                report.city_ar = result.get("city_ar")
                db.commit()
                updated += 1
                print(f"  [{i}/{len(reports)}] {report.tracking_code}: "
                      f"{result.get('address')}, {result.get('city')}")
            else:
                print(f"  [{i}/{len(reports)}] {report.tracking_code}: geocoding failed, skipped")
            if i < len(reports):
                time.sleep(1.1)  # Nominatim usage policy: max 1 req/sec

        print(f"Done. Updated {updated}/{len(reports)} reports.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
