import uuid
import boto3
from botocore.client import Config
from app.config import get_settings

settings = get_settings()


def _s3_client():
    kwargs = dict(
        region_name=settings.AWS_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    )
    if settings.AWS_S3_ENDPOINT_URL:
        kwargs["endpoint_url"] = settings.AWS_S3_ENDPOINT_URL
        kwargs["config"] = Config(signature_version="s3v4")
    return boto3.client("s3", **kwargs)


def generate_presigned_upload(filename: str, content_type: str) -> dict:
    client = _s3_client()
    key = f"reports/{uuid.uuid4()}/{filename}"
    thumb_key = f"thumbnails/{uuid.uuid4()}/{filename}"

    upload_url = client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.AWS_S3_BUCKET,
            "Key": key,
            "ContentType": content_type,
        },
        ExpiresIn=600,
    )

    # internal_base: reachable by the dashboard browser (localhost:9000)
    # public_base: reachable by mobile devices (ngrok / LAN IP)
    internal_base = settings.AWS_S3_ENDPOINT_URL or f"https://{settings.AWS_S3_BUCKET}.s3.amazonaws.com"
    public_base = settings.AWS_S3_PUBLIC_URL or internal_base

    # Rewrite the presigned upload URL so mobile devices can reach MinIO
    if settings.AWS_S3_PUBLIC_URL and settings.AWS_S3_ENDPOINT_URL:
        upload_url = upload_url.replace(settings.AWS_S3_ENDPOINT_URL, settings.AWS_S3_PUBLIC_URL, 1)

    # photo_url uses internal_base so the dashboard browser can load images directly
    # from localhost:9000 — no ngrok interstitial, no CORS issue for <img> tags
    photo_url = f"{internal_base}/{settings.AWS_S3_BUCKET}/{key}"
    thumbnail_url = f"{internal_base}/{settings.AWS_S3_BUCKET}/{thumb_key}"

    return {
        "upload_url": upload_url,
        "photo_url": photo_url,
        "thumbnail_url": thumbnail_url,
    }


def upload_photo(data: bytes, filename: str, content_type: str) -> dict:
    """Upload photo bytes directly to MinIO. Returns a relative path URL
    that clients resolve against their own API base URL via GET /reports/photo/{key}."""
    key = f"reports/{uuid.uuid4()}/{filename}"
    client = _s3_client()
    client.put_object(
        Bucket=settings.AWS_S3_BUCKET,
        Key=key,
        Body=data,
        ContentType=content_type,
    )
    # Relative URL: /reports/photo/{key}
    # - Dashboard prepends http://localhost:8000/v1
    # - Mobile prepends its configured backend base URL
    photo_url = f"/reports/photo/{key}"
    return {"photo_url": photo_url, "thumbnail_url": photo_url}


def get_photo(key: str) -> tuple[bytes, str]:
    """Fetch photo bytes and content-type from MinIO for proxy streaming."""
    client = _s3_client()
    obj = client.get_object(Bucket=settings.AWS_S3_BUCKET, Key=key)
    return obj["Body"].read(), obj.get("ContentType", "image/jpeg")


def delete_object(key: str) -> None:
    client = _s3_client()
    client.delete_object(Bucket=settings.AWS_S3_BUCKET, Key=key)
