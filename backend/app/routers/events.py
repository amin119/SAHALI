import asyncio
import json

import redis.asyncio as aioredis
from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import JSONResponse, StreamingResponse

from app.config import get_settings
from app.database import SessionLocal
from app.models.user import User, UserRole
from app.services.event_bus import CHANNEL
from app.services.sse_ticket import consume_ticket, issue_ticket
from app.utils.deps import require_staff

router = APIRouter(prefix="/events", tags=["events"])

_KEEPALIVE_SECONDS = 20


async def _stream(request: Request, municipality_id: int | None):
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
                raw = msg["data"].decode()
                if municipality_id is not None:
                    try:
                        event_municipality_id = json.loads(raw).get("municipality_id")
                    except ValueError:
                        event_municipality_id = None
                    if event_municipality_id != municipality_id:
                        continue
                yield f"data: {raw}\n\n"
                last_sent = now
            elif now - last_sent > _KEEPALIVE_SECONDS:
                yield ": keepalive\n\n"
                last_sent = now
    finally:
        await pubsub.unsubscribe(CHANNEL)
        await r.aclose()


@router.post("/ticket")
def create_sse_ticket(current_user: User = Depends(require_staff)):
    """Issues a 60-second, single-use ticket for opening the SSE stream below.
    Exists because EventSource can't set an Authorization header, so a real
    access token would otherwise have to sit in the URL (and therefore in
    server logs / browser history) for its full lifetime — a one-time ticket
    that dies in a minute is a much smaller thing to leak."""
    return {"ticket": issue_ticket(str(current_user.id))}


@router.get("/reports")
def report_events(request: Request, ticket: str = Query(...)):
    """SSE stream of report lifecycle events for dashboard clients, gated by
    a ticket minted via POST /events/ticket (see docstring there).

    Deliberately a sync def, not async: consume_ticket and SessionLocal are
    both blocking calls, and FastAPI runs sync route functions in a worker
    thread rather than on the event loop — an async def here would run that
    blocking preflight work directly on the loop instead. The returned
    StreamingResponse still streams _stream's async generator normally;
    that's independent of whether this outer function is sync or async."""
    try:
        user_id = consume_ticket(ticket)
        if not user_id:
            raise ValueError("invalid or expired ticket")
        with SessionLocal() as db:
            user = db.get(User, user_id)
        if not user or not user.is_active or user.role == UserRole.citizen:
            raise ValueError("not staff")
    except Exception:
        return JSONResponse({"detail": "Unauthorized"}, status_code=401)

    return StreamingResponse(
        _stream(request, user.municipality_id),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",
            "Connection": "keep-alive",
        },
    )
