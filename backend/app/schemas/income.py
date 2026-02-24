import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class IncomeCreate(BaseModel):
    amount: Decimal = Field(gt=0)
    source_type: str
    received_at: datetime
    note: str | None = None
    is_recurring: bool = False
    recurring_period: str = "none"


class IncomeUpdate(BaseModel):
    amount: Decimal | None = Field(default=None, gt=0)
    source_type: str | None = None
    received_at: datetime | None = None
    note: str | None = None
    is_recurring: bool | None = None
    recurring_period: str | None = None


class IncomeRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    amount: Decimal
    source_type: str
    received_at: datetime
    note: str | None
    is_recurring: bool
    recurring_period: str
    created_at: datetime

    model_config = {"from_attributes": True}
