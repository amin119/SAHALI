"""Workflow redesign: remove scheduled/closed statuses, multi-agent assignment, resolution report

Revision ID: 0003
Revises: 0002
Create Date: 2026-06-28
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── 1. Migrate data away from removed enum values ─────────────────────────
    op.execute("UPDATE reports SET status = 'in_progress' WHERE status = 'scheduled'")
    op.execute("UPDATE reports SET status = 'resolved'    WHERE status = 'closed'")
    op.execute("UPDATE report_status_history SET from_status = 'in_progress' WHERE from_status = 'scheduled'")
    op.execute("UPDATE report_status_history SET from_status = 'resolved'    WHERE from_status = 'closed'")
    op.execute("UPDATE report_status_history SET to_status   = 'in_progress' WHERE to_status   = 'scheduled'")
    op.execute("UPDATE report_status_history SET to_status   = 'resolved'    WHERE to_status   = 'closed'")

    # ── 2. Swap enum type (PostgreSQL can't drop values directly) ────────────
    op.execute("ALTER TABLE reports ALTER COLUMN status TYPE VARCHAR(50)")
    op.execute("ALTER TABLE report_status_history ALTER COLUMN from_status TYPE VARCHAR(50)")
    op.execute("ALTER TABLE report_status_history ALTER COLUMN to_status   TYPE VARCHAR(50)")
    op.execute("ALTER TABLE reports ALTER COLUMN status DROP DEFAULT")
    op.execute("DROP TYPE IF EXISTS reportstatus CASCADE")
    op.execute(
        "CREATE TYPE reportstatus AS ENUM "
        "('submitted','received','under_review','in_progress','resolved','rejected')"
    )
    op.execute(
        "ALTER TABLE reports ALTER COLUMN status "
        "TYPE reportstatus USING status::reportstatus"
    )
    op.execute(
        "ALTER TABLE reports ALTER COLUMN status "
        "SET DEFAULT 'submitted'::reportstatus"
    )
    op.execute(
        "ALTER TABLE report_status_history ALTER COLUMN from_status "
        "TYPE reportstatus USING from_status::reportstatus"
    )
    op.execute(
        "ALTER TABLE report_status_history ALTER COLUMN to_status "
        "TYPE reportstatus USING to_status::reportstatus"
    )

    # ── 3. Add analyzed_by to reports ────────────────────────────────────────
    op.add_column(
        "reports",
        sa.Column("analyzed_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
    )

    # ── 4. Create assignments table ──────────────────────────────────────────
    op.create_table(
        "assignments",
        sa.Column("id",          postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("report_id",   postgresql.UUID(as_uuid=True), sa.ForeignKey("reports.id", ondelete="CASCADE"), nullable=False),
        sa.Column("agent_id",    postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"),  nullable=False),
        sa.Column("assigned_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"),  nullable=False),
        sa.Column("note",        sa.Text,    nullable=True),
        sa.Column("is_active",   sa.Boolean, nullable=False, server_default="true"),
        sa.Column("created_at",  sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_assignments_report_id", "assignments", ["report_id"])
    op.create_index("ix_assignments_agent_id",  "assignments", ["agent_id"])

    # ── 5. Create resolution_reports table ───────────────────────────────────
    op.create_table(
        "resolution_reports",
        sa.Column("id",          postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("report_id",   postgresql.UUID(as_uuid=True), sa.ForeignKey("reports.id", ondelete="CASCADE"), nullable=False, unique=True),
        sa.Column("resolved_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"),  nullable=False),
        sa.Column("comment",     sa.Text,    nullable=False),
        sa.Column("materials",   sa.Text,    nullable=True),
        sa.Column("photo_url",   sa.Text,    nullable=True),
        sa.Column("created_at",  sa.DateTime(timezone=True), server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table("resolution_reports")
    op.drop_table("assignments")
    op.drop_column("reports", "analyzed_by")

    # Restore old enum with SCHEDULED and CLOSED
    op.execute("ALTER TABLE reports ALTER COLUMN status TYPE VARCHAR(50)")
    op.execute("ALTER TABLE report_status_history ALTER COLUMN from_status TYPE VARCHAR(50)")
    op.execute("ALTER TABLE report_status_history ALTER COLUMN to_status   TYPE VARCHAR(50)")
    op.execute("DROP TYPE IF EXISTS reportstatus")
    op.execute(
        "CREATE TYPE reportstatus AS ENUM "
        "('submitted','received','under_review','scheduled','in_progress','resolved','closed','rejected')"
    )
    op.execute(
        "ALTER TABLE reports ALTER COLUMN status "
        "TYPE reportstatus USING status::reportstatus"
    )
    op.execute(
        "ALTER TABLE report_status_history ALTER COLUMN from_status "
        "TYPE reportstatus USING from_status::reportstatus"
    )
    op.execute(
        "ALTER TABLE report_status_history ALTER COLUMN to_status "
        "TYPE reportstatus USING to_status::reportstatus"
    )
