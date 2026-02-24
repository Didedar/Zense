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
    goal_contribution_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"))
    reserve_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"))
    fun_spending_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"))
    essentials_planned: Mapped[Decimal] = mapped_column(Numeric(14, 2), default=Decimal("0"))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC), onupdate=lambda: datetime.now(UTC))

    category_limits = relationship("BudgetCategoryLimit", back_populates="budget_plan", lazy="selectin")


class BudgetCategoryLimit(Base):
    __tablename__ = "budget_category_limits"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    budget_plan_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("budget_plans.id", ondelete="CASCADE"), index=True)
    category: Mapped[str] = mapped_column(String(50), nullable=False)
    limit_amount: Mapped[Decimal] = mapped_column(Numeric(14, 2), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC), onupdate=lambda: datetime.now(UTC))

    budget_plan = relationship("BudgetPlan", back_populates="category_limits")
