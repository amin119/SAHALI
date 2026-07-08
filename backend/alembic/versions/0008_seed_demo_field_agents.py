"""Seed 20 demo field_agent accounts, one per major municipality

Idempotent/additive only — uses ON CONFLICT (email) DO NOTHING, so re-running
this migration (or running it after these rows already exist) is a no-op.
Does not touch or remove any existing users.

These are clearly-marked TEST/DEMO accounts (a "@sahali.tn" test domain,
sequential names) going into a PRODUCTION database, so — unlike the
existing dev-only scripts/seed.py, which hardcodes a shared demo password —
each account here gets its own randomly-generated password, printed once to
stdout when this migration runs and never written to disk or git. Whoever
runs `alembic upgrade head` must capture that output; it cannot be
recovered afterwards (only the bcrypt hash is stored). Swap in real staff
accounts via the admin panel before relying on these for anything beyond
testing the field-agent workflow.

Revision ID: 0008
Revises: 0007
Create Date: 2026-07-08
"""
import secrets
import uuid
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0008"
down_revision: Union[str, None] = "0007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _generate_password() -> str:
    # 16-char alphanumeric-plus-symbol, cryptographically random per agent.
    alphabet = "abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%"
    return "".join(secrets.choice(alphabet) for _ in range(16))


# (full_name, email, municipality_name)
AGENTS = [
    ("Agent Tunis",       "agent.tunis@sahali.tn",       "Tunis"),
    ("Agent Sfax",        "agent.sfax@sahali.tn",        "Sfax"),
    ("Agent Sousse",      "agent.sousse@sahali.tn",      "Sousse"),
    ("Agent Bizerte",     "agent.bizerte@sahali.tn",     "Bizerte"),
    ("Agent Ariana",      "agent.ariana@sahali.tn",      "Ariana"),
    ("Agent Ben Arous",   "agent.benarous@sahali.tn",    "Ben Arous"),
    ("Agent Nabeul",      "agent.nabeul@sahali.tn",      "Nabeul"),
    ("Agent Kairouan",    "agent.kairouan@sahali.tn",    "Kairouan"),
    ("Agent Gabès",       "agent.gabes@sahali.tn",       "Gabès"),
    ("Agent Gafsa",       "agent.gafsa@sahali.tn",       "Gafsa"),
    ("Agent Médenine",    "agent.medenine@sahali.tn",    "Medenine"),
    ("Agent Monastir",    "agent.monastir@sahali.tn",    "Monastir"),
    ("Agent Mahdia",      "agent.mahdia@sahali.tn",      "Mahdia"),
    ("Agent Kasserine",   "agent.kasserine@sahali.tn",   "Kasserine"),
    ("Agent Sidi Bouzid", "agent.sidibouzid@sahali.tn",  "Sidi Bouzid"),
    ("Agent Jendouba",    "agent.jendouba@sahali.tn",    "Jendouba"),
    ("Agent Le Kef",      "agent.lekef@sahali.tn",       "El Kef"),
    ("Agent Siliana",     "agent.siliana@sahali.tn",     "Siliana"),
    ("Agent Zaghouan",    "agent.zaghouan@sahali.tn",    "Zaghouan"),
    ("Agent Tataouine",   "agent.tataouine@sahali.tn",   "Tataouine"),
]


def upgrade() -> None:
    # Imported lazily so a missing/changed app module can't break `alembic
    # history`/autogenerate for unrelated migrations — only `upgrade()` needs it.
    from app.utils.security import hash_password

    conn = op.get_bind()
    created: list[tuple[str, str]] = []

    for full_name, email, municipality_name in AGENTS:
        muni_id = conn.execute(
            sa.text("SELECT id FROM municipalities WHERE name = :name"),
            {"name": municipality_name},
        ).scalar()
        if muni_id is None:
            # Shouldn't happen (0007 seeds this name), but don't fail the
            # whole migration over one bad lookup.
            continue

        already_exists = conn.execute(
            sa.text("SELECT 1 FROM users WHERE email = :email"),
            {"email": email},
        ).scalar()
        if already_exists:
            continue

        password = _generate_password()
        conn.execute(
            sa.text(
                """
                INSERT INTO users (id, role, full_name, email, password_hash, municipality_id)
                VALUES (:id, 'field_agent', :full_name, :email, :password_hash, :municipality_id)
                ON CONFLICT (email) DO NOTHING
                """
            ),
            {
                "id": str(uuid.uuid4()),
                "full_name": full_name,
                "email": email,
                "password_hash": hash_password(password),
                "municipality_id": muni_id,
            },
        )
        created.append((email, password))

    if created:
        print("\n" + "=" * 60)
        print("Demo field_agent accounts created — SAVE THESE NOW.")
        print("These passwords are not stored anywhere and cannot be")
        print("recovered; only the bcrypt hash is kept in the database.")
        print("=" * 60)
        for email, password in created:
            print(f"  {email}  {password}")
        print("=" * 60 + "\n")


def downgrade() -> None:
    conn = op.get_bind()
    emails = [email for _, email, _ in AGENTS]
    conn.execute(
        sa.text("DELETE FROM users WHERE email = ANY(:emails) AND role = 'field_agent'"),
        {"emails": emails},
    )
