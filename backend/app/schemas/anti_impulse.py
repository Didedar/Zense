import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class AntiImpulseStartRequest(BaseModel):
    planned_purchase_amount: Decimal = Field(gt=0)
    category: str


class AntiImpulseStartResponse(BaseModel):
    session_id: uuid.UUID
    risk_score: int
    cooldown_seconds: int
    goal_impact_days: int | None
    recommended_intervention: str
    message: str


class AntiImpulseResolveRequest(BaseModel):
    outcome: str


class AntiImpulseSessionRead(BaseModel):
    id: uuid.UUID
    planned_purchase_amount: Decimal
    category: str
    risk_score: int
    cooldown_seconds: int
    goal_impact_days: int | None
    outcome: str
    created_at: datetime
    resolved_at: datetime | None

    model_config = {"from_attributes": True}
