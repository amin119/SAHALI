import hmac

import redis as redis_lib

from app.config import get_settings
from app.utils.security import generate_otp

settings = get_settings()
_redis = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)

OTP_TTL = 300  # 5 minutes
MAX_VERIFY_ATTEMPTS = 5  # per OTP lifetime — resets when a fresh code is requested


def _attempts_exhausted(attempts_key: str) -> bool:
    """INCR is atomic, so concurrent verify calls can't all read the same
    pre-increment count and slip past the limit together (a plain GET+SETEX
    would allow exactly that race)."""
    attempts = _redis.incr(attempts_key)
    if attempts == 1:
        _redis.expire(attempts_key, OTP_TTL)
    return attempts > MAX_VERIFY_ATTEMPTS


# ── Phone OTP ──────────────────────────────────────────────────────────────────

def store_otp(phone: str, code: str) -> None:
    _redis.setex(f"otp:{phone}", OTP_TTL, code)
    _redis.delete(f"otp_attempts:{phone}")


def verify_otp(phone: str, code: str) -> bool:
    if _attempts_exhausted(f"otp_attempts:{phone}"):
        return False
    stored = _redis.get(f"otp:{phone}")
    if stored and hmac.compare_digest(stored, code):
        _redis.delete(f"otp:{phone}")
        _redis.delete(f"otp_attempts:{phone}")
        return True
    return False


def send_otp(phone: str) -> str:
    code = generate_otp()
    store_otp(phone, code)
    _dispatch_sms(phone, f"Votre code de vérification Sahali est : {code}")
    return code


def _dispatch_sms(phone: str, message: str) -> None:
    try:
        from twilio.rest import Client
        client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        client.messages.create(body=message, from_=settings.TWILIO_FROM_NUMBER, to=phone)
    except Exception:
        pass


# ── Email OTP ──────────────────────────────────────────────────────────────────

def store_email_otp(email: str, purpose: str, code: str) -> None:
    _redis.setex(f"email_otp:{purpose}:{email}", OTP_TTL, code)
    _redis.delete(f"email_otp_attempts:{purpose}:{email}")


def verify_email_otp(email: str, code: str, purpose: str) -> bool:
    key = f"email_otp:{purpose}:{email}"
    if _attempts_exhausted(f"email_otp_attempts:{purpose}:{email}"):
        return False
    stored = _redis.get(key)
    if stored and hmac.compare_digest(stored, code):
        _redis.delete(key)
        _redis.delete(f"email_otp_attempts:{purpose}:{email}")
        return True
    return False


def send_email_otp(email: str, purpose: str) -> str:
    code = generate_otp()
    store_email_otp(email, purpose, code)
    if purpose == "verify":
        subject = "Vérification de votre email Sahali"
        body = (
            f"Votre code de vérification est : {code}\n"
            "Ce code est valable 5 minutes.\n\n"
            "Si vous n'avez pas demandé ce code, ignorez ce message."
        )
    else:
        subject = "Réinitialisation de votre mot de passe Sahali"
        body = (
            f"Votre code de réinitialisation est : {code}\n"
            "Ce code est valable 5 minutes.\n\n"
            "Si vous n'avez pas demandé cette réinitialisation, ignorez ce message."
        )
    _dispatch_email(email, subject, body)
    return code


def _dispatch_email(to: str, subject: str, body: str) -> None:
    try:
        import sendgrid
        from sendgrid.helpers.mail import Mail
        sg = sendgrid.SendGridAPIClient(settings.SENDGRID_API_KEY)
        msg = Mail(
            from_email=settings.EMAIL_FROM,
            to_emails=to,
            subject=subject,
            plain_text_content=body,
        )
        sg.send(msg)
    except Exception:
        pass
