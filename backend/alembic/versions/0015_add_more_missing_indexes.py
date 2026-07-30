"""Add more missing indexes — Postgres doesn't index foreign key columns
automatically, and these are exactly the ones every dashboard page's most
common queries filter or join on (report status, a report's own history/
assignments, a citizen's own reports, an agent's own assignments).

Revision ID: 0015
Revises: 0014
Create Date: 2026-07-30
"""
from typing import Sequence, Union
from alembic import op

revision: str = "0015"
down_revision: Union[str, None] = "0014"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index("ix_reports_status", "reports", ["status"], if_not_exists=True)
    op.create_index("ix_reports_citizen_id", "reports", ["citizen_id"], if_not_exists=True)
    op.create_index("ix_report_status_history_report_id", "report_status_history", ["report_id"], if_not_exists=True)
    op.create_index("ix_assignments_report_id", "assignments", ["report_id"], if_not_exists=True)
    op.create_index("ix_assignments_agent_id", "assignments", ["agent_id"], if_not_exists=True)


def downgrade() -> None:
    op.drop_index("ix_assignments_agent_id", table_name="assignments", if_exists=True)
    op.drop_index("ix_assignments_report_id", table_name="assignments", if_exists=True)
    op.drop_index("ix_report_status_history_report_id", table_name="report_status_history", if_exists=True)
    op.drop_index("ix_reports_citizen_id", table_name="reports", if_exists=True)
    op.drop_index("ix_reports_status", table_name="reports", if_exists=True)
