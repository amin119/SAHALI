import uuid
import redis as redis_lib
from app.config import get_settings

settings = get_settings()
_redis = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)

TICKET_TTL_SECONDS = 60


def issue_ticket(user_id: str) -> str:
    ticket = str(uuid.uuid4())
    _redis.setex(f"sse_ticket:{ticket}", TICKET_TTL_SECONDS, user_id)
    return ticket


def consume_ticket(ticket: str) -> str | None:
    """One-time use: the ticket is deleted as soon as it's read, so a value
    seen in a log or browser history can't be replayed to open a stream."""
    key = f"sse_ticket:{ticket}"
    user_id = _redis.get(key)
    if user_id is not None:
        _redis.delete(key)
    return user_id
