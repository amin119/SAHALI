"""Add photo_urls/video_url/voice_note_url to resolution_reports

Revision ID: 0011
Revises: 0010
Create Date: 2026-07-10
"""
from typing import Sequence, Union
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB

revision: str = "0011"
down_revision: Union[str, None] = "0010"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("resolution_reports", sa.Column("photo_urls", JSONB(), nullable=True))
    op.add_column("resolution_reports", sa.Column("video_url", sa.Text(), nullable=True))
    op.add_column("resolution_reports", sa.Column("voice_note_url", sa.Text(), nullable=True))

    # Preserve any existing single photo_url by backfilling it into the new array.
    op.execute("""
        UPDATE resolution_reports
        SET photo_urls = jsonb_build_array(photo_url)
        WHERE photo_url IS NOT NULL AND photo_urls IS NULL
    """)


def downgrade() -> None:
    op.drop_column("resolution_reports", "voice_note_url")
    op.drop_column("resolution_reports", "video_url")
    op.drop_column("resolution_reports", "photo_urls")
