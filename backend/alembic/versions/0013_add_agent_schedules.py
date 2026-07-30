"""Add agent_schedules — recurring weekly working hours per staff member,
used to tell who's actually on shift when assigning a report

Revision ID: 0013
Revises: 0012
Create Date: 2026-07-30
"""
from typing import Sequence, Union
import sqlalchemy as sa
from alembic import op

revision: str = "0013"
down_revision: Union[str, None] = "0012"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "agent_schedules",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("agent_id", sa.UUID, sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("day_of_week", sa.Integer(), nullable=False),
        sa.Column("start_time", sa.Time(), nullable=False),
        sa.Column("end_time", sa.Time(), nullable=False),
        sa.UniqueConstraint("agent_id", "day_of_week", name="uq_agent_schedule_agent_day"),
    )
    op.create_index("ix_agent_schedules_agent_id", "agent_schedules", ["agent_id"])


def downgrade() -> None:
    op.drop_index("ix_agent_schedules_agent_id", table_name="agent_schedules")
    op.drop_table("agent_schedules")
