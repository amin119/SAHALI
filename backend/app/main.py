import structlog
import sentry_sdk
from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.config import get_settings
from app.routers import auth, users, reports, notifications, admin, categories, events
from app.utils.deps import require_super_admin

settings = get_settings()

if settings.SENTRY_DSN:
    sentry_sdk.init(dsn=settings.SENTRY_DSN, traces_sample_rate=0.2)

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer(),
    ]
)

limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.RATE_LIMIT_PER_MINUTE}/minute"])

app = FastAPI(
    title="Citizen Alert API",
    version="1.0.0",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

_cors_origins = ["*"] if settings.CORS_ORIGINS == "*" else [o.strip() for o in settings.CORS_ORIGINS.split(",")]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins,
    allow_origin_regex=r"https://.*\.vercel\.app",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
API_PREFIX = "/v1"
app.include_router(auth.router, prefix=API_PREFIX)
app.include_router(users.router, prefix=API_PREFIX)
app.include_router(reports.router, prefix=API_PREFIX)
app.include_router(notifications.router, prefix=API_PREFIX)
app.include_router(admin.router, prefix=API_PREFIX)
app.include_router(categories.router, prefix=API_PREFIX)
app.include_router(events.router, prefix=API_PREFIX)


@app.get("/health")
def health():
    return {"status": "ok", "version": "1.0.0"}


@app.get("/health/db")
def health_db(_=Depends(require_super_admin)):
    """Ops diagnostic — gated to super-admin. Reports ok/error only, never
    raw exception text or which specific account exists, so it can't be used
    for unauthenticated reconnaissance."""
    from app.database import engine, SessionLocal
    from sqlalchemy import text
    from app.models.user import User, UserRole
    from app.utils.security import _get_private_key, _get_public_key
    log = structlog.get_logger()
    result: dict = {}
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        result["db"] = "ok"
    except Exception as e:
        log.warning("health_db_check_failed", check="db", error=str(e))
        result["db"] = "error"
    try:
        db = SessionLocal()
        result["admin_account_exists"] = db.query(User).filter(User.role == UserRole.admin).first() is not None
        db.close()
    except Exception as e:
        log.warning("health_db_check_failed", check="admin_account", error=str(e))
        result["admin_account_exists"] = "error"
    try:
        _get_private_key()
        result["jwt_private"] = "ok"
    except Exception as e:
        log.warning("health_db_check_failed", check="jwt_private", error=str(e))
        result["jwt_private"] = "error"
    try:
        _get_public_key()
        result["jwt_public"] = "ok"
    except Exception as e:
        log.warning("health_db_check_failed", check="jwt_public", error=str(e))
        result["jwt_public"] = "error"
    return result
