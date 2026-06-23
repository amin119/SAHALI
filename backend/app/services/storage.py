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

    base_url = settings.AWS_S3_ENDPOINT_URL or f"https://{settings.AWS_S3_BUCKET}.s3.amazonaws.com"
    photo_url = f"{base_url}/{settings.AWS_S3_BUCKET}/{key}"
    thumbnail_url = f"{base_url}/{settings.AWS_S3_BUCKET}/{thumb_key}"

    return {
        "upload_url": upload_url,
        "photo_url": photo_url,
        "thumbnail_url": thumbnail_url,
    }


def delete_object(key: str) -> None:
    client = _s3_client()
    client.delete_object(Bucket=settings.AWS_S3_BUCKET, Key=key)
