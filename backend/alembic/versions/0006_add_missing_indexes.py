"""Add missing indexes on frequently filtered/sorted columns

Revision ID: 0006
Revises: f21d1a94a219
Create Date: 2026-07-05
"""
from typing import Sequence, Union
from alembic import op

revision: str = "0006"
down_revision: Union[str, None] = "f21d1a94a219"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index("ix_reports_category_id", "reports", ["category_id"], if_not_exists=True)
    op.create_index("ix_reports_city", "reports", ["city"], if_not_exists=True)
    op.create_index("ix_reports_created_at", "reports", ["created_at"], if_not_exists=True)
    op.create_index("ix_reports_assigned_to", "reports", ["assigned_to"], if_not_exists=True)
    op.create_index("ix_users_municipality_id", "users", ["municipality_id"], if_not_exists=True)


def downgrade() -> None:
    op.drop_index("ix_users_municipality_id", table_name="users", if_exists=True)
    op.drop_index("ix_reports_assigned_to", table_name="reports", if_exists=True)
    op.drop_index("ix_reports_created_at", table_name="reports", if_exists=True)
    op.drop_index("ix_reports_city", table_name="reports", if_exists=True)
    op.drop_index("ix_reports_category_id", table_name="reports", if_exists=True)
