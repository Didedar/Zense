from fastapi import APIRouter

from app.core.deps import CurrentUser, DbSession
from app.schemas.notification import MarkReadRequest, MarkReadResponse, NotificationListResponse
from app.services.notification_service import get_notifications, get_unread_count, mark_all_read, mark_as_read

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/", response_model=NotificationListResponse)
async def list_notifications(user: CurrentUser, db: DbSession, unread_only: bool = False):
    return await get_notifications(db, user.id, unread_only)


@router.get("/unread-count")
async def unread_count(user: CurrentUser, db: DbSession):
    count = await get_unread_count(db, user.id)
    return {"unread_count": count}


@router.post("/mark-read", response_model=MarkReadResponse)
async def mark_read(data: MarkReadRequest, user: CurrentUser, db: DbSession):
    count = await mark_as_read(db, user.id, data.notification_ids)
    return {"marked_count": count}


@router.post("/mark-all-read", response_model=MarkReadResponse)
async def mark_all_read_endpoint(user: CurrentUser, db: DbSession):
    count = await mark_all_read(db, user.id)
    return {"marked_count": count}
