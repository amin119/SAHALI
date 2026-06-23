"""
Creates the first admin (or supervisor) user.
Run from the backend directory:
    uv run python scripts/create_admin.py
"""
import sys
import uuid
from pathlib import Path

# make sure the app package is importable
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.database import SessionLocal
from app.models.user import User, UserRole
from app.utils.security import hash_password

EMAIL    = "admin@sahali.tn"
PASSWORD = "Admin1234!"
NAME     = "Administrateur Sahali"
ROLE     = UserRole.admin   # change to UserRole.supervisor if preferred

def main():
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == EMAIL).first()
        if existing:
            print(f"User already exists: {EMAIL}")
            return

        user = User(
            id=uuid.uuid4(),
            full_name=NAME,
            email=EMAIL,
            password_hash=hash_password(PASSWORD),
            role=ROLE,
            preferred_language="fr",
            is_active=True,
        )
        db.add(user)
        db.commit()
        print(f"Created {ROLE.value} account:")
        print(f"  Email   : {EMAIL}")
        print(f"  Password: {PASSWORD}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
