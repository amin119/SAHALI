import httpx
import structlog

log = structlog.get_logger()

NOMINATIM_REVERSE_URL = "https://nominatim.openstreetmap.org/reverse"
USER_AGENT = "SahaliApp/1.0 (contact: support@sahali.tn)"


def _extract_address_city(data: dict) -> dict:
    addr = data.get("address", {}) or {}
    city = (
        addr.get("city") or addr.get("town") or addr.get("village")
        or addr.get("municipality") or addr.get("county")
    )
    road = addr.get("road") or addr.get("pedestrian") or addr.get("neighbourhood")
    street = " ".join(p for p in [addr.get("house_number"), road] if p) or None
    return {"address": street, "city": city}


async def reverse_geocode(lat: float, lng: float) -> dict | None:
    """Best-effort reverse geocode of (lat, lng) via OSM Nominatim.
    Returns {"address": street|None, "city": city|None}, or None on failure."""
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            resp = await client.get(
                NOMINATIM_REVERSE_URL,
                params={"format": "jsonv2", "lat": lat, "lon": lng, "zoom": 18, "addressdetails": 1},
                headers={"User-Agent": USER_AGENT},
            )
            resp.raise_for_status()
            return _extract_address_city(resp.json())
    except Exception as e:
        log.warning("reverse_geocode_failed", lat=lat, lng=lng, error=str(e))
        return None
