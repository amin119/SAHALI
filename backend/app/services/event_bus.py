import json
import redis
from app.config import get_settings

CHANNEL = "sahali:report_events"

_client: redis.Redis | None = None


def _get_client() -> redis.Redis:
    global _client
    if _client is None:
        _client = redis.from_url(get_settings().REDIS_URL)
    return _client


def publish_report_event(event_type: str, payload: dict) -> None:
    """Publish a report lifecycle event. Never raises — callers must not be broken by Redis failures."""
    try:
        _get_client().publish(CHANNEL, json.dumps({"type": event_type, **payload}))
    except Exception:
        pass
