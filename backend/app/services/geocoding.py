import asyncio

import httpx
import structlog

log = structlog.get_logger()

NOMINATIM_REVERSE_URL = "https://nominatim.openstreetmap.org/reverse"
NOMINATIM_SEARCH_URL = "https://nominatim.openstreetmap.org/search"
USER_AGENT = "SahaliApp/1.0 (contact: support@sahali.tn)"


def _extract_address_city(data: dict) -> dict:
    addr = data.get("address", {}) or {}
    city = (
        addr.get("city") or addr.get("town") or addr.get("village")
        or addr.get("municipality") or addr.get("county")
    )
    # Only trust an actual named road — OSM's suburb/neighbourhood polygons
    # in Tunisia are often imprecise or missing, so substituting one in as a
    # "street" is more likely to be wrong than to be helpful. City stays
    # reliable, so leave address empty rather than guess.
    road = addr.get("road") or addr.get("pedestrian")
    street = " ".join(p for p in [addr.get("house_number"), road] if p) or None
    return {"address": street, "city": city}


async def _reverse_geocode_lang(lat: float, lng: float, lang: str) -> dict | None:
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            resp = await client.get(
                NOMINATIM_REVERSE_URL,
                params={"format": "jsonv2", "lat": lat, "lon": lng, "zoom": 18, "addressdetails": 1},
                headers={"User-Agent": USER_AGENT, "Accept-Language": lang},
            )
            resp.raise_for_status()
            return _extract_address_city(resp.json())
    except Exception as e:
        log.warning("reverse_geocode_failed", lat=lat, lng=lng, lang=lang, error=str(e))
        return None


async def reverse_geocode(lat: float, lng: float) -> dict | None:
    """Best-effort reverse geocode of (lat, lng) via OSM Nominatim, in both
    French and Arabic (two sequential requests, spaced to respect Nominatim's
    1 request/second usage policy). Returns
    {"address": str|None, "city": str|None, "address_ar": str|None, "city_ar": str|None},
    or None if both requests fail."""
    fr = await _reverse_geocode_lang(lat, lng, "fr")
    await asyncio.sleep(1.1)
    ar = await _reverse_geocode_lang(lat, lng, "ar")

    if not fr and not ar:
        return None
    fr = fr or {}
    ar = ar or {}
    return {
        "address": fr.get("address"),
        "city": fr.get("city"),
        "address_ar": ar.get("address"),
        "city_ar": ar.get("city"),
    }


async def forward_geocode(query: str) -> tuple[float, float] | None:
    """Best-effort forward geocode of a place name (e.g. a municipality name)
    to (lat, lng) via OSM Nominatim. Returns None on failure or no match."""
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            resp = await client.get(
                NOMINATIM_SEARCH_URL,
                params={"format": "jsonv2", "q": query, "limit": 1},
                headers={"User-Agent": USER_AGENT},
            )
            resp.raise_for_status()
            results = resp.json()
            if not results:
                return None
            return float(results[0]["lat"]), float(results[0]["lon"])
    except Exception as e:
        log.warning("forward_geocode_failed", query=query, error=str(e))
        return None
