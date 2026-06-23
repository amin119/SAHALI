import redis as redis_lib
from app.config import get_settings
from app.utils.security import generate_otp

settings = get_settings()
_redis = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)

OTP_TTL = 300  # 5 minutes


def store_otp(phone: str, code: str) -> None:
    _redis.setex(f"otp:{phone}", OTP_TTL, code)


def verify_otp(phone: str, code: str) -> bool:
    stored = _redis.get(f"otp:{phone}")
    if stored and stored == code:
        _redis.delete(f"otp:{phone}")
        return True
    return False


def send_otp(phone: str) -> str:
    code = generate_otp()
    store_otp(phone, code)
    _dispatch_sms(phone, f"Your Citizen Alert verification code is: {code}")
    return code


def _dispatch_sms(phone: str, message: str) -> None:
    try:
        from twilio.rest import Client
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        client.messages.create(body=message, from_=settings.TWILIO_FROM_NUMBER, to=phone)
    except Exception:
        # Log but don't crash — in dev mode OTP is returned via API
        pass
