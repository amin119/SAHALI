"""Initial schema

Revision ID: 0001
Revises:
Create Date: 2026-06-19
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
import geoalchemy2

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS postgis")

    op.create_table(
        "municipalities",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("boundary", geoalchemy2.types.Geometry("POLYGON", srid=4326), nullable=True),
        sa.Column("logo_url", sa.Text, nullable=True),
        sa.Column("subscription_tier", sa.String(50), nullable=True),
        sa.Column("subscription_expires", sa.Date, nullable=True),
    )

    op.create_table(
        "users",
        sa.Column("id", sa.UUID, primary_key=True),
        sa.Column("role", sa.Enum("citizen", "supervisor", "field_agent", "analyst", "admin", name="userrole"), nullable=False),
        sa.Column("full_name", sa.String(200), nullable=False),
        sa.Column("phone", sa.String(20), unique=True, nullable=True),
        sa.Column("email", sa.String(200), unique=True, nullable=True),
        sa.Column("password_hash", sa.Text, nullable=True),
        sa.Column("municipality_id", sa.Integer, sa.ForeignKey("municipalities.id"), nullable=True),
        sa.Column("fcm_token", sa.Text, nullable=True),
        sa.Column("preferred_language", sa.String(2), nullable=False, server_default="fr"),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.text("true")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "departments",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column("municipality_id", sa.Integer, sa.ForeignKey("municipalities.id"), nullable=False),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("email", sa.String(200), nullable=True),
    )

    op.create_table(
        "categories",
        sa.Column("id", sa.Integer, primary_key=True, autoincrement=True),
        sa.Column("parent_id", sa.Integer, sa.ForeignKey("categories.id"), nullable=True),
        sa.Column("slug", sa.String(100), unique=True, nullable=False),
        sa.Column("label_ar", sa.String(200), nullable=False),
        sa.Column("label_fr", sa.String(200), nullable=False),
        sa.Column("label_en", sa.String(200), nullable=False),
        sa.Column("default_department_id", sa.Integer, sa.ForeignKey("departments.id"), nullable=True),
        sa.Column("icon", sa.String(50), nullable=True),
        sa.Column("sla_hours", sa.Integer, nullable=True),
    )

    op.create_table(
        "reports",
        sa.Column("id", sa.UUID, primary_key=True),
        sa.Column("tracking_code", sa.String(10), unique=True, nullable=False),
        sa.Column("citizen_id", sa.UUID, sa.ForeignKey("users.id"), nullable=False),
        sa.Column("category_id", sa.Integer, sa.ForeignKey("categories.id"), nullable=False),
        sa.Column("status", sa.Enum(
            "submitted", "received", "under_review", "scheduled",
            "in_progress", "resolved", "closed", "rejected",
            name="reportstatus"
        ), nullable=False, server_default="submitted"),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("photo_url", sa.Text, nullable=True),
        sa.Column("thumbnail_url", sa.Text, nullable=True),
        sa.Column("location", geoalchemy2.types.Geometry("POINT", srid=4326), nullable=False),
        sa.Column("address", sa.Text, nullable=True),
        sa.Column("city", sa.String(100), nullable=True),
        sa.Column("ward", sa.String(100), nullable=True),
        sa.Column("assigned_to", sa.UUID, sa.ForeignKey("users.id"), nullable=True),
        sa.Column("department_id", sa.Integer, sa.ForeignKey("departments.id"), nullable=True),
        sa.Column("ai_category_id", sa.Integer, sa.ForeignKey("categories.id"), nullable=True),
        sa.Column("ai_confidence", sa.Float, nullable=True),
        sa.Column("is_duplicate", sa.Boolean, nullable=False, server_default=sa.text("false")),
        sa.Column("duplicate_of", sa.UUID, sa.ForeignKey("reports.id"), nullable=True),
        sa.Column("priority", sa.Enum("low", "medium", "high", "critical", name="reportpriority"),
                  nullable=False, server_default="medium"),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()),
    )

    # Spatial index for fast proximity queries
    op.create_index("idx_reports_location", "reports", ["location"], postgresql_using="gist", if_not_exists=True)
    op.create_index("idx_reports_status", "reports", ["status"], if_not_exists=True)
    op.create_index("idx_reports_citizen", "reports", ["citizen_id"], if_not_exists=True)

    op.create_table(
        "report_status_history",
        sa.Column("id", sa.UUID, primary_key=True),
        sa.Column("report_id", sa.UUID, sa.ForeignKey("reports.id"), nullable=False),
        sa.Column("from_status", sa.Enum(
            "submitted", "received", "under_review", "scheduled",
            "in_progress", "resolved", "closed", "rejected",
            name="reportstatus"
        ), nullable=True),
        sa.Column("to_status", sa.Enum(
            "submitted", "received", "under_review", "scheduled",
            "in_progress", "resolved", "closed", "rejected",
            name="reportstatus"
        ), nullable=False),
        sa.Column("changed_by", sa.UUID, sa.ForeignKey("users.id"), nullable=False),
        sa.Column("note", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table(
        "notifications",
        sa.Column("id", sa.UUID, primary_key=True),
        sa.Column("user_id", sa.UUID, sa.ForeignKey("users.id"), nullable=False),
        sa.Column("report_id", sa.UUID, sa.ForeignKey("reports.id"), nullable=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("body", sa.Text, nullable=False),
        sa.Column("is_read", sa.Boolean, nullable=False, server_default=sa.text("false")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_index("idx_notifications_user", "notifications", ["user_id"], if_not_exists=True)


def downgrade() -> None:
    op.drop_table("notifications")
    op.drop_table("report_status_history")
    op.drop_table("reports")
    op.drop_table("categories")
    op.drop_table("departments")
    op.drop_table("users")
    op.drop_table("municipalities")
    op.execute("DROP TYPE IF EXISTS reportstatus")
    op.execute("DROP TYPE IF EXISTS reportpriority")
    op.execute("DROP TYPE IF EXISTS userrole")
