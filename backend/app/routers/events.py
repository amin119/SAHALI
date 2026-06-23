import asyncio
import redis.asyncio as aioredis
from fastapi import APIRouter, Query, Request
from fastapi.responses import StreamingResponse, JSONResponse

from app.config import get_settings
from app.database import SessionLocal
from app.models.user import User, UserRole
from app.services.event_bus import CHANNEL
from app.utils.security import decode_token

router = APIRouter(prefix="/events", tags=["events"])

_KEEPALIVE_SECONDS = 20


async def _stream(request: Request):
    settings = get_settings()
    r = aioredis.from_url(settings.REDIS_URL)
    pubsub = r.pubsub()
    await pubsub.subscribe(CHANNEL)
    loop = asyncio.get_running_loop()
    last_sent = loop.time()
    try:
        while True:
            if await request.is_disconnected():
                break
            msg = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)
            now = loop.time()
            if msg and isinstance(msg.get("data"), bytes):
                yield f"data: {msg['data'].decode()}\n\n"
                last_sent = now
            elif now - last_sent > _KEEPALIVE_SECONDS:
                yield ": keepalive\n\n"
                last_sent = now
    finally:
        await pubsub.unsubscribe(CHANNEL)
        await r.aclose()


@router.get("/reports")
async def report_events(request: Request, token: str = Query(...)):
    """
    SSE stream of report lifecycle events for dashboard clients.
    Token is passed as a query param because EventSource cannot set custom headers.
    Only staff roles (admin, supervisor, field_agent, analyst) are admitted.
    """
    try:
        payload = decode_token(token)
        if payload.get("type") != "access":
            raise ValueError("wrong token type")
        with SessionLocal() as db:
            user = db.get(User, payload["sub"])
        if not user or not user.is_active or user.role == UserRole.citizen:
            raise ValueError("not staff")
    except Exception:
        return JSONResponse({"detail": "Unauthorized"}, status_code=401)

    return StreamingResponse(
        _stream(request),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
            "Connection": "keep-alive",
        },
    )
