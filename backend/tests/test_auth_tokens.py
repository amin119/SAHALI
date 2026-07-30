from tests.conftest import TEST_PASSWORD


def test_refresh_token_is_single_use(client, make_user):
    user = make_user(email="refresh-test@example.test")
    login = client.post("/v1/auth/login", json={"identifier": user.email, "password": TEST_PASSWORD})
    assert login.status_code == 200
    refresh_token = login.json()["refresh_token"]

    first = client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert first.status_code == 200

    second = client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert second.status_code == 401


def test_logout_revokes_access_and_refresh_tokens(client, make_user):
    user = make_user(email="logout-test@example.test")
    login = client.post("/v1/auth/login", json={"identifier": user.email, "password": TEST_PASSWORD})
    access_token = login.json()["access_token"]
    refresh_token = login.json()["refresh_token"]

    logout = client.post(
        "/v1/auth/logout",
        json={"refresh_token": refresh_token},
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert logout.status_code == 204

    me = client.get("/v1/users/me", headers={"Authorization": f"Bearer {access_token}"})
    assert me.status_code == 401

    refresh = client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh.status_code == 401


def test_login_rate_limit_kicks_in_after_ten_requests(client):
    body = {"identifier": "nobody-rl@example.test", "password": "wrong"}
    statuses = [client.post("/v1/auth/login", json=body).status_code for _ in range(12)]
    assert statuses[:10] == [401] * 10
    assert all(s == 429 for s in statuses[10:])
