import uuid
from datetime import UTC, date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class BudgetPlan(Base):
    __tablename__ = "budget_plans"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True)
    period_type: Mapped[str] = mapped_column(String(20), nullable=False)
    period_start: Mapped[date] = mapped_column(Date, nullable=False)
    period_end: Mapped[date] = mapped_column(Date, nullable=False)
    total_income_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"))
    top_line_income: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"), server_default="0")
    hard_commitments_total: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"), server_default="0")
    net_available: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"), server_default="0")
    reserve_pct: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=Decimal("0"), server_default="0")
    goals_pct: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=Decimal("0"), server_default="0")
    free_pct: Mapped[Decimal] = mapped_column(Numeric(5, 4), default=Decimal("0"), server_default="0")
    goal_contribution_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"))
    reserve_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"))
    flexible_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"), server_default="0")
    free_money_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"), server_default="0")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC), onupdate=lambda: datetime.now(UTC))
