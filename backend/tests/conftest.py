import os
import uuid

# Must happen before any `app.*` import — app.config.get_settings() is
# lru_cached and read at import time by app.main, app.database, etc.
#
# Deliberately read from TEST_DATABASE_URL/TEST_REDIS_URL — dedicated names,
# not DATABASE_URL/REDIS_URL — and then force those into the env unconditionally
# (not setdefault). Every test flushes Redis; if these fell back to whatever
# ambient DATABASE_URL/REDIS_URL a shell or misconfigured CI job already had
# set, that flush could hit a real dev/prod instance instead of the throwaway
# test one.
_TEST_DATABASE_URL = os.environ.get(
    "TEST_DATABASE_URL", "postgresql://citizen_alert:password@localhost:5433/citizen_alert_test"
)
_TEST_REDIS_URL = os.environ.get("TEST_REDIS_URL", "redis://localhost:6380/1")

if "test" not in _TEST_DATABASE_URL:
    raise RuntimeError(
        f"TEST_DATABASE_URL ({_TEST_DATABASE_URL!r}) doesn't look like a disposable test "
        "database (expected 'test' in the name) — refusing to run tests against it."
    )

os.environ["DATABASE_URL"] = _TEST_DATABASE_URL
os.environ["REDIS_URL"] = _TEST_REDIS_URL
os.environ["APP_ENV"] = "development"
os.environ["DEBUG"] = "true"

import pytest
import redis as redis_lib
from fastapi.testclient import TestClient

from app.main import app
from app.config import get_settings
from app.database import SessionLocal
from app.models.user import User, UserRole
from app.utils.security import hash_password

TEST_PASSWORD = "TestPass1234!"


@pytest.fixture(autouse=True)
def _flush_redis():
    """Every test starts against a clean Redis so OTP attempts, rate-limit
    counters, and SSE tickets from one test can't bleed into the next."""
    r = redis_lib.from_url(get_settings().REDIS_URL)
    r.flushdb()
    yield
    r.flushdb()


@pytest.fixture
def client():
    return TestClient(app)


@pytest.fixture
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.rollback()
        session.close()


@pytest.fixture
def make_user(db):
    """Factory fixture: make_user(role=UserRole.citizen, ...) creates and
    commits a real user for the test, and deletes it afterward."""
    created: list[User] = []

    def _make(role: UserRole = UserRole.citizen, password: str = TEST_PASSWORD, **kwargs) -> User:
        user = User(
            id=uuid.uuid4(),
            full_name=kwargs.pop("full_name", "Test User"),
            email=kwargs.pop("email", f"test-{uuid.uuid4().hex[:8]}@example.test"),
            role=role,
            password_hash=hash_password(password),
            is_active=kwargs.pop("is_active", True),
            preferred_language="fr",
            **kwargs,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        created.append(user)
        return user

    yield _make

    for user in created:
        db.delete(user)
    db.commit()
