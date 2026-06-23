import httpx
import structlog
from app.config import get_settings

settings = get_settings()
log = structlog.get_logger()


async def analyze_report(
    report_id: str,
    text: str,
    photo_url: str | None,
    lat: float,
    lng: float,
    language: str,
) -> dict | None:
    payload = {
        "report_id": report_id,
        "text": text or "",
        "photo_url": photo_url,
        "location": {"lat": lat, "lng": lng},
        "language": language,
    }
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(f"{settings.AI_SERVICE_URL}/ai/analyze", json=payload)
            resp.raise_for_status()
            return resp.json()
    except Exception as e:
        log.warning("ai_analyze_failed", error=str(e))
        return None
