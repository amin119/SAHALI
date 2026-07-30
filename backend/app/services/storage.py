import re
import uuid
import httpx
import boto3
from urllib.parse import quote
from botocore.client import Config
from app.config import get_settings

settings = get_settings()


def _sanitize_filename(filename: str) -> str:
    """Keeps only the basename and strips anything but safe characters, so a
    crafted filename (e.g. containing `../` or a full path) can't influence
    the storage key beyond its own segment."""
    base = filename.replace("\\", "/").rsplit("/", 1)[-1]
    base = re.sub(r"[^A-Za-z0-9._-]", "_", base).lstrip(".")
    return base[:200] or "file"


# ── Supabase Storage REST (preferred on Render) ──────────────────────────────

def _supabase_upload(data: bytes, key: str, content_type: str) -> str:
    """Upload bytes to Supabase Storage via REST API; returns public CDN URL."""
    bucket = quote(settings.AWS_S3_BUCKET, safe="")
    url = f"{settings.SUPABASE_URL}/storage/v1/object/{bucket}/{key}"
    headers = {
        "Authorization": f"Bearer {settings.SUPABASE_SERVICE_KEY}",
        "Content-Type": content_type,
        "x-upsert": "true",
    }
    resp = httpx.post(url, content=data, headers=headers, timeout=30)
    resp.raise_for_status()
    return f"{settings.SUPABASE_URL}/storage/v1/object/public/{bucket}/{key}"


# ── S3 / MinIO (local dev fallback) ──────────────────────────────────────────

def _s3_client():
    kwargs = dict(
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    )
    if settings.AWS_S3_ENDPOINT_URL:
        kwargs["endpoint_url"] = settings.AWS_S3_ENDPOINT_URL
        kwargs["config"] = Config(
            signature_version="s3v4",
            s3={"addressing_style": "path"},
        )
    return boto3.client("s3", **kwargs)


def _s3_upload(data: bytes, key: str, content_type: str) -> str:
    client = _s3_client()
    client.put_object(
        Bucket=settings.AWS_S3_BUCKET,
        Key=key,
        Body=data,
        ContentType=content_type,
    )
    if settings.AWS_S3_PUBLIC_BASE_URL:
        return f"{settings.AWS_S3_PUBLIC_BASE_URL}/{key}"
    return f"/reports/photo/{key}"


# ── Public API ────────────────────────────────────────────────────────────────

def upload_photo(data: bytes, filename: str, content_type: str) -> dict:
    key = f"reports/{uuid.uuid4()}/{_sanitize_filename(filename)}"
    if settings.SUPABASE_URL and settings.SUPABASE_SERVICE_KEY:
        photo_url = _supabase_upload(data, key, content_type)
    else:
        photo_url = _s3_upload(data, key, content_type)
    return {"photo_url": photo_url, "thumbnail_url": photo_url}


def generate_presigned_upload(filename: str, content_type: str) -> dict:
    client = _s3_client()
    safe_filename = _sanitize_filename(filename)
    key = f"reports/{uuid.uuid4()}/{safe_filename}"
    thumb_key = f"thumbnails/{uuid.uuid4()}/{safe_filename}"

    upload_url = client.generate_presigned_url(
        "put_object",
        Params={"Bucket": settings.AWS_S3_BUCKET, "Key": key, "ContentType": content_type},
        ExpiresIn=600,
    )

    internal_base = settings.AWS_S3_ENDPOINT_URL or f"https://{settings.AWS_S3_BUCKET}.s3.amazonaws.com"
    public_base = settings.AWS_S3_PUBLIC_URL or internal_base
    if settings.AWS_S3_PUBLIC_URL and settings.AWS_S3_ENDPOINT_URL:
        upload_url = upload_url.replace(settings.AWS_S3_ENDPOINT_URL, settings.AWS_S3_PUBLIC_URL, 1)

    photo_url = f"{internal_base}/{settings.AWS_S3_BUCKET}/{key}"
    thumbnail_url = f"{internal_base}/{settings.AWS_S3_BUCKET}/{thumb_key}"
    return {"upload_url": upload_url, "photo_url": photo_url, "thumbnail_url": thumbnail_url}


def get_photo(key: str) -> tuple[bytes, str]:
    client = _s3_client()
    obj = client.get_object(Bucket=settings.AWS_S3_BUCKET, Key=key)
    return obj["Body"].read(), obj.get("ContentType", "image/jpeg")


def delete_object(key: str) -> None:
    client = _s3_client()
    client.delete_object(Bucket=settings.AWS_S3_BUCKET, Key=key)
