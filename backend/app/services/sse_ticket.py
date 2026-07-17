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
    """One-time use: GETDEL reads and deletes atomically, so two concurrent
    requests can't both read the ticket before either deletes it — a plain
    GET-then-DELETE would leave exactly that replay window open."""
    return _redis.getdel(f"sse_ticket:{ticket}")
