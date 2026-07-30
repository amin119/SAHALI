import math
from datetime import UTC, datetime

import redis as redis_lib

from app.config import get_settings

settings = get_settings()
_redis = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)

_PREFIX = "revoked_jti:"


def _ttl_seconds(expires_at: datetime) -> int:
    """Rounds up, not down — truncating with int() could set a TTL up to
    ~1s shorter than the token's real remaining life, letting the denylist
    entry (or a single-use claim) expire slightly before the token itself
    does."""
    remaining = (expires_at - datetime.now(UTC)).total_seconds()
    return math.ceil(remaining) if remaining > 0 else 0


def revoke(jti: str, expires_at: datetime) -> None:
    """Denylists a token's jti until its own expiry — after that it can't be
    replayed anyway, so the Redis key is left to expire with it rather than
    growing the denylist forever."""
    ttl = _ttl_seconds(expires_at)
    if ttl > 0:
        _redis.setex(f"{_PREFIX}{jti}", ttl, "1")


def is_revoked(jti: str) -> bool:
    return bool(_redis.exists(f"{_PREFIX}{jti}"))


def consume_once(jti: str, expires_at: datetime) -> bool:
    """Atomically claims a jti for one-time use — SET...NX is a single Redis
    round trip, so two concurrent calls with the same jti can't both see it
    as unclaimed the way a separate exists-then-set check would. Returns True
    the first time (this call owns the claim), False on any later call
    (already used or already expired)."""
    ttl = _ttl_seconds(expires_at)
    if ttl <= 0:
        return False
    return bool(_redis.set(f"{_PREFIX}{jti}", "1", ex=ttl, nx=True))
