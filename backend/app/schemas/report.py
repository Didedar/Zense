import uuid
from datetime import date, datetime

from pydantic import BaseModel


class WeeklyReportRead(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    week_start: date
    week_end: date
    summary_json: dict
    summary_text: str
    created_at: datetime

    model_config = {"from_attributes": True}
