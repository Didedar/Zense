import uuid
from datetime import datetime

from pydantic import BaseModel


class ProfileRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    display_name: str
    age: int | None = None
    segment: str
    currency: str
    timezone: str
    onboarding_completed: bool
    spending_style: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ProfileUpdate(BaseModel):
    display_name: str | None = None
    age: int | None = None
    segment: str | None = None
    currency: str | None = None
    timezone: str | None = None
    spending_style: str | None = None


class OnboardingComplete(BaseModel):
    segment: str
    monthly_income: float
    goals: list[dict]
    spending_style: str = "medium"


class OnboardingResult(BaseModel):
    budget_recommendation: dict
    safe_to_spend_today: float
    first_actions: list[str]
