"""
Creates the first admin (or supervisor) user with a randomly generated
password printed once to stdout — never hardcode a real credential here.
Run from the backend directory:
    uv run python scripts/create_admin.py
"""
import secrets
import string
import sys
import uuid
from pathlib import Path

# make sure the app package is importable
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.models.user import User, UserRole
from app.utils.security import hash_password

EMAIL = "admin@sahali.tn"
NAME  = "Administrateur Sahali"
ROLE  = UserRole.admin   # change to UserRole.supervisor if preferred


def _generate_password(length: int = 16) -> str:
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*"
    return "".join(secrets.choice(alphabet) for _ in range(length))


def main():
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == EMAIL).first()
        if existing:
            print(f"User already exists: {EMAIL}")
            return

        password = _generate_password()
        user = User(
            id=uuid.uuid4(),
            full_name=NAME,
            email=EMAIL,
            password_hash=hash_password(password),
            role=ROLE,
            preferred_language="fr",
            is_active=True,
        )
        db.add(user)
        db.commit()
        print(f"Created {ROLE.value} account:")
        print(f"  Email   : {EMAIL}")
        print(f"  Password: {password}")
        print("Store this password now — it will not be shown again.")
    finally:
        db.close()

if __name__ == "__main__":
    main()
