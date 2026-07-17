def test_otp_lockout_after_five_wrong_attempts(client):
    phone = "+21699000001"
    resp = client.post("/v1/auth/otp/request", json={"phone": phone})
    assert resp.status_code == 200
    real_code = resp.json()["debug_code"]

    for _ in range(5):
        r = client.post("/v1/auth/otp/verify", json={"phone": phone, "code": "000000"})
        assert r.status_code == 400

    # Attempts are exhausted now — even the real code is rejected.
    r = client.post("/v1/auth/otp/verify", json={"phone": phone, "code": real_code})
    assert r.status_code == 400


def test_fresh_otp_request_resets_the_lockout(client):
    phone = "+21699000002"
    client.post("/v1/auth/otp/request", json={"phone": phone})
    for _ in range(5):
        client.post("/v1/auth/otp/verify", json={"phone": phone, "code": "000000"})

    resp = client.post("/v1/auth/otp/request", json={"phone": phone})
    fresh_code = resp.json()["debug_code"]

    r = client.post("/v1/auth/otp/verify", json={"phone": phone, "code": fresh_code})
    assert r.status_code == 200
    assert "access_token" in r.json()
