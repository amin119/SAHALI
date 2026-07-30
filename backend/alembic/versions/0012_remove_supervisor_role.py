"""Remove supervisor role — collapses into admin, which already had every
supervisor permission plus more (require_supervisor was always admin-or-supervisor)

Revision ID: 0012
Revises: 0011
Create Date: 2026-07-30
"""
from typing import Sequence, Union
from alembic import op

revision: str = "0012"
down_revision: Union[str, None] = "0011"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

OLD_VALUES = ("citizen", "supervisor", "field_agent", "analyst", "admin")
NEW_VALUES = ("citizen", "field_agent", "analyst", "admin")


def upgrade() -> None:
    # Any existing supervisor accounts become municipal/super admins — the
    # closest equivalent role, and municipality_id (already a separate column)
    # is preserved as-is, so a municipal supervisor becomes a municipal admin.
    op.execute("UPDATE users SET role = 'admin' WHERE role = 'supervisor'")

    # Postgres has no ALTER TYPE ... DROP VALUE, so the enum type is rebuilt:
    # drop the DB-level dependency (cast column to text), recreate the type
    # without 'supervisor', then cast the column back.
    op.execute("ALTER TABLE users ALTER COLUMN role TYPE VARCHAR USING role::text")
    op.execute("DROP TYPE userrole")
    op.execute(f"CREATE TYPE userrole AS ENUM {NEW_VALUES}")
    op.execute("ALTER TABLE users ALTER COLUMN role TYPE userrole USING role::userrole")


def downgrade() -> None:
    op.execute("ALTER TABLE users ALTER COLUMN role TYPE VARCHAR USING role::text")
    op.execute("DROP TYPE userrole")
    op.execute(f"CREATE TYPE userrole AS ENUM {OLD_VALUES}")
    op.execute("ALTER TABLE users ALTER COLUMN role TYPE userrole USING role::userrole")
