from datetime import datetime, timezone
import redis as redis_lib
from app.config import get_settings

settings = get_settings()
_redis = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)

_PREFIX = "revoked_jti:"


def revoke(jti: str, expires_at: datetime) -> None:
    """Denylists a token's jti until its own expiry — after that it can't be
    replayed anyway, so the Redis key is left to expire with it rather than
    growing the denylist forever."""
    ttl = int((expires_at - datetime.now(timezone.utc)).total_seconds())
    if ttl > 0:
        _redis.setex(f"{_PREFIX}{jti}", ttl, "1")


def is_revoked(jti: str) -> bool:
    return bool(_redis.exists(f"{_PREFIX}{jti}"))
