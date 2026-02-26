from datetime import datetime

from pydantic import BaseModel


class QuestTemplateRead(BaseModel):
    id: str
    slug: str
    title: str
    description: str
    category: str
    difficulty: str
    xp_reward: int
    target_value: int
    action_type: str
    icon_emoji: str
    is_repeatable: bool

    model_config = {"from_attributes": True}


class UserQuestRead(BaseModel):
    id: str
    quest_template_id: str
    status: str
    current_value: int
    target_value: int
    title: str
    description: str
    xp_reward: int
    icon_emoji: str
    difficulty: str
    progress_percent: float
    started_at: datetime
    completed_at: datetime | None = None

    model_config = {"from_attributes": True}


class QuestListResponse(BaseModel):
    active: list[UserQuestRead]
    completed: list[UserQuestRead]
    available: list[QuestTemplateRead]


class QuestProgressUpdate(BaseModel):
    quest_id: str
    new_value: int
