import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class ExpenseCreate(BaseModel):
    amount: Decimal = Field(gt=0)
    category: str
    spent_at: datetime
    merchant_name: str | None = None
    note: str | None = None
    is_impulse_flag: bool = False
    is_fixed: bool = False
    expense_kind: str = "variable" # "fixed", "variable", or "auto"


class ExpenseUpdate(BaseModel):
    amount: Decimal | None = Field(default=None, gt=0)
    category: str | None = None
    spent_at: datetime | None = None
    merchant_name: str | None = None
    note: str | None = None
    is_impulse_flag: bool | None = None
    is_fixed: bool | None = None
    expense_kind: str | None = None


class ExpenseRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    amount: Decimal
    category: str
    spent_at: datetime
    merchant_name: str | None
    note: str | None
    is_impulse_flag: bool
    is_fixed: bool
    expense_kind: str
    created_at: datetime

    model_config = {"from_attributes": True}
