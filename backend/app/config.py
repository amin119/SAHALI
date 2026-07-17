from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Literal


class Settings(BaseSettings):
    APP_ENV: Literal["development", "staging", "production"] = "development"
    DEBUG: bool = True

    # JWT — file paths for local dev, base64 env vars for production (Render)
    JWT_PRIVATE_KEY_PATH: str = "./private.pem"
    JWT_PUBLIC_KEY_PATH: str = "./public.pem"
    JWT_PRIVATE_KEY_B64: str = ""
    JWT_PUBLIC_KEY_B64: str = ""
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Database
    DATABASE_URL: str = "postgresql://citizen_alert:password@localhost:5432/citizen_alert_db"
    DB_POOL_SIZE: int = 2
    DB_MAX_OVERFLOW: int = 4

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Storage — Supabase REST (preferred, set these two on Render)
    SUPABASE_URL: str = ""          # https://<ref>.supabase.co
    SUPABASE_SERVICE_KEY: str = ""  # service_role key from Supabase Settings → API

    # Storage — S3/MinIO fallback (local dev)
    STORAGE_BACKEND: Literal["s3", "minio"] = "minio"
    AWS_ACCESS_KEY_ID: str = "minioadmin"
    AWS_SECRET_ACCESS_KEY: str = "minioadmin"
    AWS_S3_BUCKET: str = "citizen-alert"
    AWS_S3_ENDPOINT_URL: str | None = "http://localhost:9000"
    AWS_S3_PUBLIC_URL: str | None = None
    AWS_S3_PUBLIC_BASE_URL: str | None = None
    AWS_REGION: str = "us-east-1"

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"

    # Twilio
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_FROM_NUMBER: str = ""

    # SendGrid
    SENDGRID_API_KEY: str = ""
    EMAIL_FROM: str = "noreply@citizenalert.tn"

    # AI service
    AI_SERVICE_URL: str = "http://localhost:8001"

    # Sentry
    SENTRY_DSN: str = ""

    # CORS — "*" for dev, comma-separated origins for production
    CORS_ORIGINS: str = "*"
    # Unset by default — a wildcard here would authorize every *.vercel.app
    # app, not just yours. Set it only once you know your project's domain
    # (e.g. r"https://sahali-dashboard(-[a-z0-9-]+)?\.vercel\.app" to also
    # cover preview deploys). The stable production URL doesn't need this at
    # all — just add it to CORS_ORIGINS directly.
    CORS_VERCEL_ORIGIN_REGEX: str | None = None

    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 100

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
