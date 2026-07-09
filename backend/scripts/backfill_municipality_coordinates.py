"""
One-time forward-geocode of every municipality name to a centroid point,
used to auto-route reports to their nearest municipality. Safe to re-run —
only touches rows where location is still null. Respects Nominatim's
1 request/second usage policy (~335 municipalities => ~6 minutes).

Run from the backend directory, with DATABASE_URL pointed at whichever
database you want to update (local or Supabase/prod):
    python scripts/backfill_municipality_coordinates.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.services.backfill import backfill_municipality_coordinates


def main():
    db = SessionLocal()
    try:
        result = backfill_municipality_coordinates(db)
        print(f"Done. Updated {result['updated']}/{result['total']} municipalities.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
