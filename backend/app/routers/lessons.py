import uuid

from fastapi import APIRouter
from pydantic import BaseModel

from app.core.deps import CurrentUser, DbSession
from app.schemas.micro_lesson import LessonCompleteResponse, LessonHistoryRead, MicroLessonTriggerResponse
from app.services.micro_lesson_service import check_trigger, complete_lesson, get_lesson_history

router = APIRouter(prefix="/lessons", tags=["Micro-Lessons"])


class TriggerCheckRequest(BaseModel):
    event: str
    context: dict | None = None


class LessonCompleteRequest(BaseModel):
    lesson_id: str


@router.post("/check-trigger", response_model=MicroLessonTriggerResponse)
async def check_lesson_trigger(data: TriggerCheckRequest, user: CurrentUser, db: DbSession):
    result = await check_trigger(db, user.id, data.event, data.context)
    if result is None:
        return {"lesson": None, "triggered": False, "trigger_reason": ""}
    return result


@router.post("/complete", response_model=LessonCompleteResponse)
async def complete_lesson_endpoint(data: LessonCompleteRequest, user: CurrentUser, db: DbSession):
    return await complete_lesson(db, user.id, uuid.UUID(data.lesson_id))


@router.get("/history", response_model=list[LessonHistoryRead])
async def lesson_history(user: CurrentUser, db: DbSession, limit: int = 20):
    return await get_lesson_history(db, user.id, limit)
