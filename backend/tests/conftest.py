import os
import uuid

# Must happen before any `app.*` import — app.config.get_settings() is
# lru_cached and read at import time by app.main, app.database, etc.
os.environ.setdefault("DATABASE_URL", "postgresql://citizen_alert:password@localhost:5433/citizen_alert_test")
os.environ.setdefault("REDIS_URL", "redis://localhost:6380/1")  # db 1 — separate from local dev's db 0
os.environ.setdefault("APP_ENV", "development")
os.environ.setdefault("DEBUG", "true")

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
