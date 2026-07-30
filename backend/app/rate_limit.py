from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import get_settings

settings = get_settings()

# A single shared Limiter instance — imported by main.py (to register it on the
# app) and by individual routers (to apply tighter per-route limits). Living
# in its own module avoids routers importing from main.py, which would be
# circular since main.py imports the routers.
# storage_uri points at Redis so counts are shared across worker processes —
# Render runs multiple uvicorn workers (see Dockerfile), and the in-memory
# default would let each worker enforce the limit independently, effectively
# multiplying it by the worker count.
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[f"{settings.RATE_LIMIT_PER_MINUTE}/minute"],
    storage_uri=settings.REDIS_URL,
)
