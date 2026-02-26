from fastapi import APIRouter

from app.core.deps import CurrentUser, DbSession
from app.schemas.xp import XPAwardResponse, XPHistoryResponse, XPOverview, XPTransactionRead
from app.services.xp_service import get_xp_history, get_xp_overview

router = APIRouter(prefix="/xp", tags=["XP & Gamification"])


@router.get("/overview", response_model=XPOverview)
async def xp_overview(user: CurrentUser, db: DbSession):
    return await get_xp_overview(db, user.id)


@router.get("/history", response_model=XPHistoryResponse)
async def xp_history(user: CurrentUser, db: DbSession, limit: int = 50):
    transactions = await get_xp_history(db, user.id, limit)
    overview = await get_xp_overview(db, user.id)
    return {
        "transactions": transactions,
        "total_xp": overview["total_xp"],
        "level": overview["level"],
    }
