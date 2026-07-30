from __future__ import annotations
import structlog
from sqlalchemy.orm import Session
from app.models.notification import Notification
from app.models.user import User, UserRole
from app.models.report import Report
from app.config import get_settings

settings = get_settings()
log = structlog.get_logger()

# Notification templates keyed by (event, language). `event` is normalized
# to uppercase before lookup, since callers pass both the uppercase literal
# ("SUBMITTED") and the lowercase ReportStatus enum value (e.g. "resolved").
_TEMPLATES: dict[tuple[str, str], dict] = {
    ("SUBMITTED", "en"): {"title": "Report received", "body": "Your report #{code} has been received."},
    ("SUBMITTED", "fr"): {"title": "Signalement reçu", "body": "Votre signalement #{code} a été reçu."},
    ("SUBMITTED", "ar"): {"title": "تم استلام البلاغ", "body": "تم استلام بلاغك #{code}."},
    ("RECEIVED", "en"): {"title": "Report acknowledged", "body": "Report #{code} has been acknowledged by the responsible department."},
    ("RECEIVED", "fr"): {"title": "Signalement pris en charge", "body": "Votre signalement #{code} a été pris en charge par le service concerné."},
    ("RECEIVED", "ar"): {"title": "تم تولي البلاغ", "body": "تم تولي بلاغك #{code} من طرف المصلحة المعنية."},
    ("UNDER_REVIEW", "en"): {"title": "Report under review", "body": "Report #{code} is currently being reviewed."},
    ("UNDER_REVIEW", "fr"): {"title": "Signalement en cours d'examen", "body": "Votre signalement #{code} est en cours d'examen."},
    ("UNDER_REVIEW", "ar"): {"title": "البلاغ قيد الدراسة", "body": "بلاغك #{code} قيد الدراسة حاليا."},
    ("IN_PROGRESS", "en"): {"title": "Work in progress", "body": "Report #{code} is now being handled."},
    ("IN_PROGRESS", "fr"): {"title": "Intervention en cours", "body": "Le traitement du signalement #{code} a commencé."},
    ("IN_PROGRESS", "ar"): {"title": "جارٍ التعامل مع البلاغ", "body": "بدأ التعامل مع بلاغك #{code}."},
    ("RESOLVED", "en"): {"title": "Issue resolved", "body": "Report #{code} at {address} has been resolved."},
    ("RESOLVED", "fr"): {"title": "Problème résolu", "body": "Le signalement #{code} à {address} a été résolu."},
    ("RESOLVED", "ar"): {"title": "تم حل المشكلة", "body": "تم حل البلاغ #{code} في {address}."},
    ("REJECTED", "en"): {"title": "Report rejected", "body": "Report #{code} could not be processed."},
    ("REJECTED", "fr"): {"title": "Signalement rejeté", "body": "Votre signalement #{code} n'a pas pu être traité."},
    ("REJECTED", "ar"): {"title": "تم رفض البلاغ", "body": "لم يتم قبول معالجة بلاغك #{code}."},
}


def _get_template(event: str, lang: str) -> dict:
    event = event.upper()
    return _TEMPLATES.get((event, lang), _TEMPLATES.get((event, "en"), {"title": event, "body": ""}))


def notify_citizen(db: Session, report: Report, event: str) -> None:
    citizen: User = report.citizen
    lang = citizen.preferred_language or "fr"
    tmpl = _get_template(event, lang)
    title = tmpl["title"]
    body = tmpl["body"].format(code=report.tracking_code, address=report.address or "")

    notif = Notification(user_id=citizen.id, report_id=report.id, title=title, body=body)
    db.add(notif)
    db.flush()

    _send_push(citizen.fcm_token, title, body)


def notify_staff(db: Session, report: Report) -> None:
    """Create in-app notifications and send emails to all active admins."""
    staff = (
        db.query(User)
        .filter(User.role == UserRole.admin)
        .filter(User.is_active == True)  # noqa: E712
        .all()
    )
    title = f"Nouveau signalement — {report.city or 'Inconnue'}"
    body = f"#{report.tracking_code} · {report.title}"

    for member in staff:
        db.add(Notification(user_id=member.id, report_id=report.id, title=title, body=body))
        if member.email:
            _send_email(member.email, member.full_name, report)

    db.flush()


def _send_email(to_email: str, name: str, report: Report) -> None:
    if not settings.SENDGRID_API_KEY:
        return
    try:
        from sendgrid import SendGridAPIClient
        from sendgrid.helpers.mail import Mail
        html = f"""
        <div style="font-family:sans-serif;max-width:560px;margin:auto">
          <div style="background:#0038AF;padding:24px 32px;border-radius:8px 8px 0 0">
            <h1 style="color:#fff;margin:0;font-size:20px">Nouveau signalement reçu</h1>
          </div>
          <div style="background:#f8faff;padding:24px 32px;border:1px solid #e2e8f0;border-top:none;border-radius:0 0 8px 8px">
            <p style="color:#334155;margin-top:0">Bonjour <strong>{name}</strong>,</p>
            <p style="color:#334155">Un nouveau signalement vient d'être soumis et attend votre traitement.</p>
            <table style="width:100%;border-collapse:collapse;margin:16px 0">
              <tr><td style="padding:8px 0;color:#64748b;font-size:13px;width:110px">Code</td>
                  <td style="padding:8px 0;font-weight:600;font-family:monospace">{report.tracking_code}</td></tr>
              <tr><td style="padding:8px 0;color:#64748b;font-size:13px">Titre</td>
                  <td style="padding:8px 0">{report.title}</td></tr>
              <tr><td style="padding:8px 0;color:#64748b;font-size:13px">Ville</td>
                  <td style="padding:8px 0">{report.city or '—'}</td></tr>
              <tr><td style="padding:8px 0;color:#64748b;font-size:13px">Adresse</td>
                  <td style="padding:8px 0">{report.address or '—'}</td></tr>
            </table>
            <p style="color:#94a3b8;font-size:12px;margin-bottom:0">
              Connectez-vous au tableau de bord Sahali pour traiter ce signalement.
            </p>
          </div>
        </div>
        """
        message = Mail(
            from_email=settings.EMAIL_FROM,
            to_emails=to_email,
            subject=f"[Sahali] Nouveau signalement #{report.tracking_code}",
            html_content=html,
        )
        SendGridAPIClient(settings.SENDGRID_API_KEY).send(message)
    except Exception as e:
        log.warning("email_failed", to=to_email, error=str(e))


def _send_push(fcm_token: str | None, title: str, body: str) -> None:
    if not fcm_token:
        return
    try:
        import firebase_admin
        from firebase_admin import messaging, credentials
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
        msg = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=fcm_token,
        )
        messaging.send(msg)
    except Exception as e:
        log.warning("push_failed", error=str(e))
