from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field


class PurchaseImpactRequest(BaseModel):
    purchase_amount: Decimal = Field(gt=0)
    category: str
    planned_date: date | None = None


class GoalImpact(BaseModel):
    goal_id: str
    goal_title: str
    eta_shift_days: int
    new_estimated_date: date | None


class PurchaseImpactResponse(BaseModel):
    is_safe_now: bool
    safe_to_spend_today: float
    budget_impact: dict
    goal_impacts: list[GoalImpact]
    recommendation: str
    reasoning: str
