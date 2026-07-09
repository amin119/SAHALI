"""Add municipality centroid location + reports.municipality_id link

Revision ID: 0010
Revises: 0009
Create Date: 2026-07-09
"""
from typing import Sequence, Union
import sqlalchemy as sa
from alembic import op
import geoalchemy2

revision: str = "0010"
down_revision: Union[str, None] = "0009"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "municipalities",
        sa.Column("location", geoalchemy2.Geometry("POINT", srid=4326), nullable=True),
    )
    op.add_column(
        "reports",
        sa.Column("municipality_id", sa.Integer(), sa.ForeignKey("municipalities.id", ondelete="SET NULL"), nullable=True),
    )
    op.create_index("ix_reports_municipality_id", "reports", ["municipality_id"], if_not_exists=True)


def downgrade() -> None:
    op.drop_index("ix_reports_municipality_id", table_name="reports", if_exists=True)
    op.drop_column("reports", "municipality_id")
    op.drop_column("municipalities", "location")
