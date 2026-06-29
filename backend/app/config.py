from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Literal


class Settings(BaseSettings):
    APP_ENV: Literal["development", "staging", "production"] = "development"
    SECRET_KEY: str = "change-me-in-production"
    DEBUG: bool = True

    # JWT
    JWT_PRIVATE_KEY_PATH: str = "./private.pem"
    JWT_PUBLIC_KEY_PATH: str = "./public.pem"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Database
    DATABASE_URL: str = "postgresql://citizen_alert:password@localhost:5432/citizen_alert_db"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # Storage
    STORAGE_BACKEND: Literal["s3", "minio"] = "minio"
    AWS_ACCESS_KEY_ID: str = "minioadmin"
    AWS_SECRET_ACCESS_KEY: str = "minioadmin"
    AWS_S3_BUCKET: str = "citizen-alert"
    AWS_S3_ENDPOINT_URL: str | None = "http://localhost:9000"
    # Public URL used in pre-signed upload URLs returned to mobile clients.
    # Must be reachable from the device:
    #   emulator  → http://10.0.2.2:9000
    #   same WiFi → http://192.168.X.X:9000
    #   ngrok     → run `ngrok http 9000` and paste the https URL
    AWS_S3_PUBLIC_URL: str | None = None
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

    # Rate limiting
    RATE_LIMIT_PER_MINUTE: int = 100
    USER_RATE_LIMIT_PER_MINUTE: int = 20

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    return Settings()
