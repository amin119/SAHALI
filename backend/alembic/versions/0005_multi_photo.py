"""Add photo_urls JSONB array to reports

Revision ID: 0005
Revises: 0004
Create Date: 2026-06-28
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision: str = "0005"
down_revision: Union[str, None] = "0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add as nullable first, then backfill, then set NOT NULL
    op.add_column("reports", sa.Column("photo_urls", JSONB, nullable=True))
    op.execute(
        """
        UPDATE reports
        SET photo_urls = CASE
            WHEN photo_url IS NOT NULL THEN jsonb_build_array(photo_url)
            ELSE '[]'::jsonb
        END
        """
    )
    op.alter_column("reports", "photo_urls", nullable=False)


def downgrade() -> None:
    op.drop_column("reports", "photo_urls")
