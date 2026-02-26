from datetime import datetime

from pydantic import BaseModel


class NotificationRead(BaseModel):
    id: str
    title: str
    body: str
    notification_type: str
    action_url: str | None = None
    payload: dict = {}
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class NotificationListResponse(BaseModel):
    notifications: list[NotificationRead]
    unread_count: int


class MarkReadRequest(BaseModel):
    notification_ids: list[str]


class MarkReadResponse(BaseModel):
    marked_count: int
