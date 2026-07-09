import asyncio
import time

import structlog
from geoalchemy2.shape import to_shape
from sqlalchemy.orm import Session

from app.models.municipality import Municipality
from app.models.report import Report
from app.services.geocoding import forward_geocode, reverse_geocode
from app.services.municipality_matching import closest_municipality_id

log = structlog.get_logger()


def backfill_municipality_coordinates(db: Session) -> dict:
    municipalities = db.query(Municipality).filter(Municipality.location.is_(None)).all()
    log.info("backfill_municipality_coordinates_started", count=len(municipalities))

    updated = 0
    for i, m in enumerate(municipalities, start=1):
        result = asyncio.run(forward_geocode(f"{m.name}, Tunisia"))
        if result:
            lat, lng = result
            m.location = f"SRID=4326;POINT({lng} {lat})"
            db.commit()
            updated += 1
            log.info("municipality_geocoded", i=i, total=len(municipalities), name=m.name, lat=lat, lng=lng)
        else:
            log.warning("municipality_geocode_failed", i=i, total=len(municipalities), name=m.name)
        if i < len(municipalities):
            time.sleep(1.1)  # Nominatim usage policy: max 1 req/sec

    log.info("backfill_municipality_coordinates_done", updated=updated, total=len(municipalities))
    return {"updated": updated, "total": len(municipalities)}


def backfill_report_municipality(db: Session) -> dict:
    reports = (
        db.query(Report)
        .filter(Report.municipality_id.is_(None))
        .filter(Report.location.isnot(None))
        .all()
    )
    log.info("backfill_report_municipality_started", count=len(reports))

    updated = 0
    for i, report in enumerate(reports, start=1):
        point = to_shape(report.location)
        lat, lng = point.y, point.x
        municipality_id = closest_municipality_id(db, lat, lng)
        if municipality_id:
            report.municipality_id = municipality_id
            db.commit()
            updated += 1
            log.info("report_municipality_assigned", i=i, total=len(reports),
                      tracking_code=report.tracking_code, municipality_id=municipality_id)
        else:
            log.warning("report_municipality_skipped", i=i, total=len(reports),
                         tracking_code=report.tracking_code)

    log.info("backfill_report_municipality_done", updated=updated, total=len(reports))
    return {"updated": updated, "total": len(reports)}


def backfill_report_addresses(db: Session) -> dict:
    reports = (
        db.query(Report)
        .filter(Report.address.is_(None), Report.city.is_(None))
        .filter(Report.location.isnot(None))
        .all()
    )
    log.info("backfill_report_addresses_started", count=len(reports))

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
            log.info("report_address_geocoded", i=i, total=len(reports),
                      tracking_code=report.tracking_code, city=result.get("city"))
        else:
            log.warning("report_address_geocode_failed", i=i, total=len(reports),
                         tracking_code=report.tracking_code)
        if i < len(reports):
            time.sleep(1.1)  # Nominatim usage policy: max 1 req/sec

    log.info("backfill_report_addresses_done", updated=updated, total=len(reports))
    return {"updated": updated, "total": len(reports)}
