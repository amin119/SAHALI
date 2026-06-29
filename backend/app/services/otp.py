import redis as redis_lib
from app.config import get_settings
from app.utils.security import generate_otp

settings = get_settings()
_redis = redis_lib.from_url(settings.REDIS_URL, decode_responses=True)

OTP_TTL = 300  # 5 minutes


# ── Phone OTP ──────────────────────────────────────────────────────────────────

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


def verify_email_otp(email: str, code: str, purpose: str) -> bool:
    key = f"email_otp:{purpose}:{email}"
    stored = _redis.get(key)
    if stored and stored == code:
        _redis.delete(key)
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
