"""add_is_active_to_categories

Revision ID: f21d1a94a219
Revises: 0005
Create Date: 2026-07-02 11:47:59.534765

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = 'f21d1a94a219'
down_revision: Union[str, None] = '0005'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('categories', sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'))


def downgrade() -> None:
    op.drop_column('categories', 'is_active')
