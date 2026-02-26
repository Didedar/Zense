from datetime import datetime

from pydantic import BaseModel


class MicroLessonRead(BaseModel):
    id: str
    slug: str
    title: str
    body: str
    category: str
    icon_emoji: str
    xp_reward: int
    duration_seconds: int

    model_config = {"from_attributes": True}


class MicroLessonTriggerResponse(BaseModel):
    lesson: MicroLessonRead | None = None
    triggered: bool
    trigger_reason: str = ""


class LessonCompleteRequest(BaseModel):
    lesson_id: str


class LessonCompleteResponse(BaseModel):
    xp_awarded: int
    message: str


class LessonHistoryRead(BaseModel):
    id: str
    lesson_id: str
    lesson_title: str
    shown_at: datetime
    completed: bool
    xp_awarded: bool

    model_config = {"from_attributes": True}
