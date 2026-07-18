import threading

from app.models.user import UserRole
from app.services.sse_ticket import consume_ticket
from tests.conftest import TEST_PASSWORD


def _login(client, user):
    resp = client.post("/v1/auth/login", json={"identifier": user.email, "password": TEST_PASSWORD})
    assert resp.status_code == 200
    return resp.json()["access_token"]


def test_ticket_issuance_requires_staff_role(client, make_user):
    citizen = make_user(role=UserRole.citizen, email="citizen-ticket@example.test")
    token = _login(client, citizen)

    resp = client.post("/v1/events/ticket", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 403


def test_ticket_is_single_use(client, make_user):
    """Exercises the ticket mechanism directly (issue via the real endpoint,
    consume via the same function the streaming route uses) rather than
    opening an actual SSE connection — the stream's infinite keepalive loop
    doesn't resolve cleanly through a test client."""
    admin = make_user(role=UserRole.admin, email="admin-ticket@example.test")
    token = _login(client, admin)

    ticket_resp = client.post("/v1/events/ticket", headers={"Authorization": f"Bearer {token}"})
    assert ticket_resp.status_code == 200
    ticket = ticket_resp.json()["ticket"]

    assert consume_ticket(ticket) == str(admin.id)
    assert consume_ticket(ticket) is None


def test_ticket_concurrent_consumption_only_succeeds_once(client, make_user):
    """Regression guard for the GET-then-DELETE race: two consumers racing
    on the same ticket must not both get a value back. A plain
    ThreadPoolExecutor.map doesn't guarantee the two calls actually overlap
    at the Redis boundary — one could finish before the other even starts,
    which would pass even against the old non-atomic implementation. A
    Barrier forces both threads to release into consume_ticket at the same
    instant, so this actually exercises the race."""
    admin = make_user(role=UserRole.admin, email="admin-ticket-race@example.test")
    token = _login(client, admin)

    ticket_resp = client.post("/v1/events/ticket", headers={"Authorization": f"Bearer {token}"})
    ticket = ticket_resp.json()["ticket"]

    barrier = threading.Barrier(2)
    results: list[str | None] = [None, None]

    def _consume(i: int) -> None:
        barrier.wait()
        results[i] = consume_ticket(ticket)

    threads = [threading.Thread(target=_consume, args=(i,)) for i in range(2)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert results.count(str(admin.id)) == 1
    assert results.count(None) == 1


def test_invalid_ticket_is_rejected(client):
    resp = client.get("/v1/events/reports?ticket=not-a-real-ticket")
    assert resp.status_code == 401
