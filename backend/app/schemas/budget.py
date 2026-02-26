import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel


class BudgetPlanRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    period_type: str
    period_start: date
    period_end: date
    total_income_planned: Decimal
    top_line_income: Decimal
    hard_commitments_total: Decimal
    net_available: Decimal
    reserve_pct: Decimal
    goals_pct: Decimal
    free_pct: Decimal
    goal_contribution_planned: Decimal
    reserve_planned: Decimal
    flexible_planned: Decimal
    free_money_planned: Decimal
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class BudgetPlanUpdate(BaseModel):
    total_income_planned: Decimal | None = None
    top_line_income: Decimal | None = None
    hard_commitments_total: Decimal | None = None
    net_available: Decimal | None = None
    reserve_pct: Decimal | None = None
    goals_pct: Decimal | None = None
    free_pct: Decimal | None = None
    goal_contribution_planned: Decimal | None = None
    reserve_planned: Decimal | None = None
    flexible_planned: Decimal | None = None
    free_money_planned: Decimal | None = None


class BudgetGenerateRequest(BaseModel):
    period_type: str = "weekly"


class SafeToSpendResponse(BaseModel):
    top_line_income: float
    fixed_locked: float
    net_available: float
    free_limit: float
    spent_variable: float
    remaining_free: float
    
    spending_limit: float
    total_spent: float
    fixed_spent: float
    variable_spent: float
    safe_to_spend_today: float
    remaining_fun_budget: float # legacy, keeping for backward compat
    remaining_spending_budget: float
    remaining_days: int
    time_spent_pct: float
    budget_spent_pct: float
    burn_delta: float
    status: str
    warnings: list[str]
    borrow_options: list[dict] = []

class BudgetHealthCheck(BaseModel):
    status: str
    score: int
    reasons: list[str]
    recommendations: list[str]
