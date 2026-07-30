def test_otp_lockout_after_five_wrong_attempts(client):
    phone = "+21699000001"
    resp = client.post("/v1/auth/otp/request", json={"phone": phone})
    assert resp.status_code == 200
    real_code = resp.json()["debug_code"]
    # generate_otp() can produce "000000" — pick a wrong code guaranteed to
    # actually be wrong, so this test can't flake on a coincidental match.
    wrong_code = "111111" if real_code == "000000" else "000000"

    for _ in range(5):
        r = client.post("/v1/auth/otp/verify", json={"phone": phone, "code": wrong_code})
        assert r.status_code == 400

    # Attempts are exhausted now — even the real code is rejected.
    r = client.post("/v1/auth/otp/verify", json={"phone": phone, "code": real_code})
    assert r.status_code == 400


def test_fresh_otp_request_resets_the_lockout(client):
    phone = "+21699000002"
    resp = client.post("/v1/auth/otp/request", json={"phone": phone})
    real_code = resp.json()["debug_code"]
    wrong_code = "111111" if real_code == "000000" else "000000"
    for _ in range(5):
        client.post("/v1/auth/otp/verify", json={"phone": phone, "code": wrong_code})

    resp = client.post("/v1/auth/otp/request", json={"phone": phone})
    fresh_code = resp.json()["debug_code"]

    r = client.post("/v1/auth/otp/verify", json={"phone": phone, "code": fresh_code})
    assert r.status_code == 200
    assert "access_token" in r.json()
