import uuid

from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel

from app.core.deps import CurrentUser, DbSession
from app.schemas.quest import QuestListResponse, UserQuestRead
from app.services.quest_service import get_user_quests, start_quest

router = APIRouter(prefix="/quests", tags=["Quests"])


class StartQuestRequest(BaseModel):
    quest_template_id: str


@router.get("/", response_model=QuestListResponse)
async def list_quests(user: CurrentUser, db: DbSession):
    return await get_user_quests(db, user.id)


@router.post("/start", response_model=UserQuestRead, status_code=status.HTTP_201_CREATED)
async def start_quest_endpoint(data: StartQuestRequest, user: CurrentUser, db: DbSession):
    try:
        result = await start_quest(db, user.id, uuid.UUID(data.quest_template_id))
        return result
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))
