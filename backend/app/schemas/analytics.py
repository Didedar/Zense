import uuid
from datetime import datetime

from pydantic import BaseModel


class TrackEventRequest(BaseModel):
    event_name: str
    event_payload: dict = {}


class DashboardSummary(BaseModel):
    total_users: int
    total_income: float
    total_expenses: float
    total_goals: int
    active_budgets: int
    events_last_7_days: int
