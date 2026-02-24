import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class GoalCreate(BaseModel):
    title: str
    target_amount: Decimal = Field(gt=0)
    target_date: date | None = None
    priority: int = Field(default=3, ge=1, le=5)
    category: str = "custom"


class GoalUpdate(BaseModel):
    title: str | None = None
    target_amount: Decimal | None = Field(default=None, gt=0)
    target_date: date | None = None
    priority: int | None = Field(default=None, ge=1, le=5)
    status: str | None = None
    category: str | None = None


class GoalRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    title: str
    target_amount: Decimal
    current_amount: Decimal
    target_date: date | None
    priority: int
    status: str
    category: str
    created_at: datetime

    model_config = {"from_attributes": True}


class GoalContributeRequest(BaseModel):
    amount: Decimal = Field(gt=0)
    source: str = "manual"
    note: str | None = None


class GoalProgress(BaseModel):
    goal_id: uuid.UUID
    title: str
    target_amount: Decimal
    current_amount: Decimal
    remaining: Decimal
    percent_complete: float
    days_remaining: int | None
    estimated_completion_date: date | None
    weekly_contribution_needed: Decimal | None
