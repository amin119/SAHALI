"""Add address_ar/city_ar columns to reports for bilingual geocoded addresses

Revision ID: 0009
Revises: 0008
Create Date: 2026-07-09
"""
from typing import Sequence, Union
import sqlalchemy as sa
from alembic import op

revision: str = "0009"
down_revision: Union[str, None] = "0008"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("reports", sa.Column("address_ar", sa.Text(), nullable=True))
    op.add_column("reports", sa.Column("city_ar", sa.String(length=100), nullable=True))


def downgrade() -> None:
    op.drop_column("reports", "city_ar")
    op.drop_column("reports", "address_ar")
