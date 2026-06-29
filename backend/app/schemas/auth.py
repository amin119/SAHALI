from pydantic import BaseModel, EmailStr, field_validator
import re


class RegisterRequest(BaseModel):
    full_name: str
    phone: str | None = None
    email: EmailStr | None = None
    password: str | None = None
    preferred_language: str = "fr"

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v):
        if v and not re.match(r"^\+?[\d\s\-]{8,20}$", v):
            raise ValueError("Invalid phone number format")
        return v

    @field_validator("preferred_language")
    @classmethod
    def validate_language(cls, v):
        if v not in ("ar", "fr", "en"):
            raise ValueError("Language must be ar, fr, or en")
        return v


class LoginRequest(BaseModel):
    identifier: str  # phone or email
    password: str


class OTPRequest(BaseModel):
    phone: str


class OTPVerify(BaseModel):
    phone: str
    code: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class EmailVerifyRequest(BaseModel):
    email: EmailStr


class EmailVerifyConfirm(BaseModel):
    email: EmailStr
    code: str


class ForgotPasswordRequest(BaseModel):
    identifier: str  # email or phone


class ResetPasswordRequest(BaseModel):
    identifier: str
    code: str
    new_password: str
