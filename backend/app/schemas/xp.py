from datetime import datetime

from pydantic import BaseModel


class XPOverview(BaseModel):
    total_xp: int
    level: int
    streak_days: int
    xp_to_next_level: int
    level_progress_percent: float
    last_action_date: datetime | None = None

    model_config = {"from_attributes": True}


class XPTransactionRead(BaseModel):
    id: str
    action: str
    xp_amount: int
    description: str
    source_id: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class XPHistoryResponse(BaseModel):
    transactions: list[XPTransactionRead]
    total_xp: int
    level: int


class XPAwardResponse(BaseModel):
    xp_awarded: int
    total_xp: int
    level: int
    leveled_up: bool
    message: str
