"""
Assigns the nearest municipality to existing reports that don't have one yet,
using their stored lat/lng. Requires municipalities to already have
coordinates (run backfill_municipality_coordinates.py first). Safe to re-run.

Run from the backend directory, with DATABASE_URL pointed at whichever
database you want to update (local or Supabase/prod):
    python scripts/backfill_report_municipality.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.services.backfill import backfill_report_municipality


def main():
    db = SessionLocal()
    try:
        result = backfill_report_municipality(db)
        print(f"Done. Updated {result['updated']}/{result['total']} reports.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
