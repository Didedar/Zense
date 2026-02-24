import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel


class BudgetCategoryLimitRead(BaseModel):
    id: uuid.UUID
    category: str
    limit_amount: Decimal

    model_config = {"from_attributes": True}


class BudgetPlanRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    period_type: str
    period_start: date
    period_end: date
    total_income_planned: Decimal
    goal_contribution_planned: Decimal
    reserve_planned: Decimal
    fun_spending_planned: Decimal
    essentials_planned: Decimal
    is_active: bool
    category_limits: list[BudgetCategoryLimitRead] = []
    created_at: datetime

    model_config = {"from_attributes": True}


class BudgetPlanUpdate(BaseModel):
    total_income_planned: Decimal | None = None
    goal_contribution_planned: Decimal | None = None
    reserve_planned: Decimal | None = None
    fun_spending_planned: Decimal | None = None
    essentials_planned: Decimal | None = None


class BudgetGenerateRequest(BaseModel):
    period_type: str = "weekly"


class SafeToSpendResponse(BaseModel):
    safe_to_spend_today: float
    remaining_fun_budget: float
    remaining_days: int
    status: str
    warnings: list[str]


class BudgetHealthCheck(BaseModel):
    status: str
    score: int
    reasons: list[str]
    recommendations: list[str]
