from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.schemas.auth import (
    RegisterRequest, LoginRequest, OTPRequest, OTPVerify,
    TokenResponse, RefreshRequest
)
from app.models.user import User, UserRole
from app.utils.security import (
    hash_password, verify_password,
    create_access_token, create_refresh_token, decode_token
)
from app.services.otp import send_otp, verify_otp
from app.config import get_settings

router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(body: RegisterRequest, db: Session = Depends(get_db)):
    if not body.phone and not body.email:
        raise HTTPException(status_code=400, detail="Phone or email required")

    existing = None
    if body.phone:
        existing = db.query(User).filter(User.phone == body.phone).first()
    if not existing and body.email:
        existing = db.query(User).filter(User.email == body.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="User already exists")

    user = User(
        full_name=body.full_name,
        phone=body.phone,
        email=body.email,
        password_hash=hash_password(body.password) if body.password else None,
        preferred_language=body.preferred_language,
        role=UserRole.citizen,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return TokenResponse(
        access_token=create_access_token(str(user.id), user.role),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post("/login", response_model=TokenResponse)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = (
        db.query(User).filter(User.email == body.identifier).first()
        or db.query(User).filter(User.phone == body.identifier).first()
    )
    if not user or not user.password_hash:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account disabled")

    return TokenResponse(
        access_token=create_access_token(str(user.id), user.role),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post("/otp/request")
def request_otp(body: OTPRequest, db: Session = Depends(get_db)):
    code = send_otp(body.phone)
    response = {"message": "OTP sent"}
    if settings.DEBUG:
        response["debug_code"] = code
    return response


@router.post("/otp/verify", response_model=TokenResponse)
def verify_otp_endpoint(body: OTPVerify, db: Session = Depends(get_db)):
    if not verify_otp(body.phone, body.code):
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")

    user = db.query(User).filter(User.phone == body.phone).first()
    if not user:
        user = User(
            full_name="Citizen",
            phone=body.phone,
            role=UserRole.citizen,
            preferred_language="fr",
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return TokenResponse(
        access_token=create_access_token(str(user.id), user.role),
        refresh_token=create_refresh_token(str(user.id)),
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh_token(body: RefreshRequest, db: Session = Depends(get_db)):
    try:
        payload = decode_token(body.refresh_token)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Wrong token type")

    user = db.get(User, payload["sub"])
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found")

    return TokenResponse(
        access_token=create_access_token(str(user.id), user.role),
        refresh_token=create_refresh_token(str(user.id)),
    )
