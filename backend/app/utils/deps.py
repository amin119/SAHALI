from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from app.database import get_db
from app.utils.security import decode_token
from app.services.token_blacklist import is_revoked
from app.models.user import User, UserRole

bearer_scheme = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> User:
    token = credentials.credentials
    try:
        payload = decode_token(token)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")

    if payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Wrong token type")

    jti = payload.get("jti")
    if jti and is_revoked(jti):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token has been revoked")

    user = db.get(User, payload["sub"])
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive")
    return user


def require_roles(*roles: UserRole):
    def checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
        return current_user
    return checker


def is_super_admin(user: User) -> bool:
    """A super-admin is a ministry-level admin not scoped to any single
    municipality. Municipal admins are role=admin with municipality_id set,
    and are scoped by the calling code, not this role gate."""
    return user.role == UserRole.admin and user.municipality_id is None


def require_super_admin(current_user: User = Depends(get_current_user)) -> User:
    if not is_super_admin(current_user):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Super-admin only")
    return current_user


require_admin = require_roles(UserRole.admin)
require_staff = require_roles(UserRole.admin, UserRole.field_agent, UserRole.analyst)
