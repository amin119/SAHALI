"""Add municipality_categories — per-municipality category activation override

Revision ID: 0014
Revises: 0013
Create Date: 2026-07-30
"""
from typing import Sequence, Union
import sqlalchemy as sa
from alembic import op

revision: str = "0014"
down_revision: Union[str, None] = "0013"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "municipality_categories",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("municipality_id", sa.Integer(), sa.ForeignKey("municipalities.id", ondelete="CASCADE"), nullable=False),
        sa.Column("category_id", sa.Integer(), sa.ForeignKey("categories.id", ondelete="CASCADE"), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.UniqueConstraint("municipality_id", "category_id", name="uq_municipality_category"),
    )
    op.create_index("ix_municipality_categories_municipality_id", "municipality_categories", ["municipality_id"])


def downgrade() -> None:
    op.drop_index("ix_municipality_categories_municipality_id", table_name="municipality_categories")
    op.drop_table("municipality_categories")
