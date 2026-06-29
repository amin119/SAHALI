import random
import string
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from app.config import get_settings

settings = get_settings()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def _load_key(path: str) -> str:
    with open(path, "r") as f:
        return f.read()


def _get_private_key() -> str:
    if settings.JWT_PRIVATE_KEY_B64:
        import base64
        return base64.b64decode(settings.JWT_PRIVATE_KEY_B64).decode()
    return _load_key(settings.JWT_PRIVATE_KEY_PATH)


def _get_public_key() -> str:
    if settings.JWT_PUBLIC_KEY_B64:
        import base64
        return base64.b64decode(settings.JWT_PUBLIC_KEY_B64).decode()
    return _load_key(settings.JWT_PUBLIC_KEY_PATH)


def create_access_token(subject: str, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": subject, "role": role, "exp": expire, "type": "access"}
    return jwt.encode(payload, _get_private_key(), algorithm="RS256")


def create_refresh_token(subject: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)
    payload = {"sub": subject, "exp": expire, "type": "refresh"}
    return jwt.encode(payload, _get_private_key(), algorithm="RS256")


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, _get_public_key(), algorithms=["RS256"])
    except JWTError as e:
        raise ValueError(f"Invalid token: {e}")


def generate_otp(length: int = 6) -> str:
    return "".join(random.choices(string.digits, k=length))


def generate_tracking_code() -> str:
    prefix = "CA"
    suffix = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
    return f"{prefix}{suffix}"
