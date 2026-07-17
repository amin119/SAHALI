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


def test_invalid_ticket_is_rejected(client):
    resp = client.get("/v1/events/reports?ticket=not-a-real-ticket")
    assert resp.status_code == 401
