from fastapi import APIRouter

from app.core.deps import CurrentUser, DbSession
from app.schemas.ai_coach import CoachAskRequest, CoachAskResponse, CoachInsight
from app.services.ai_coach_service import coach_orchestrator

router = APIRouter(prefix="/ai/coach", tags=["AI Coach"])


@router.post("/ask", response_model=CoachAskResponse)
async def ask(data: CoachAskRequest, user: CurrentUser, db: DbSession):
    result = await coach_orchestrator.ask(db, user.id, data.user_message)
    return result


@router.get("/insights/latest", response_model=list[CoachInsight])
async def insights(user: CurrentUser, db: DbSession):
    return await coach_orchestrator.get_latest_insights(db, user.id)
