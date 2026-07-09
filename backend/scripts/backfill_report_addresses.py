"""
Reverse-geocodes existing reports whose address/city are still null, using
their stored lat/lng. Safe to re-run — only touches rows where both fields
are still empty. Respects Nominatim's 1 request/second usage policy.

Run from the backend directory, with DATABASE_URL pointed at whichever
database you want to backfill (local or Supabase/prod):
    python scripts/backfill_report_addresses.py
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.services.backfill import backfill_report_addresses


def main():
    db = SessionLocal()
    try:
        result = backfill_report_addresses(db)
        print(f"Done. Updated {result['updated']}/{result['total']} reports.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
