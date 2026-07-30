from sqlalchemy import Column, ForeignKey, Integer, Time, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.database import Base


class AgentSchedule(Base):
    """One recurring weekly working-hours block for a staff member — e.g.
    "Monday 08:00-16:00". Used to tell which agents are actually on shift
    right now when assigning a report, instead of guessing from workload alone."""
    __tablename__ = "agent_schedules"

    id = Column(Integer, primary_key=True, autoincrement=True)
    agent_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    day_of_week = Column(Integer, nullable=False)  # 0=Monday .. 6=Sunday (Python date.weekday())
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)

    agent = relationship("User")

    __table_args__ = (
        UniqueConstraint("agent_id", "day_of_week", name="uq_agent_schedule_agent_day"),
    )
