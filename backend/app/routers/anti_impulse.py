import uuid

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import and_, select

from app.core.deps import CurrentUser, DbSession
from app.models.anti_impulse import AntiImpulseSession
from app.schemas.anti_impulse import (
    AntiImpulseResolveRequest,
    AntiImpulseSessionRead,
    AntiImpulseStartRequest,
    AntiImpulseStartResponse,
)
from app.services.anti_impulse_service import resolve_session, start_session

router = APIRouter(prefix="/anti-impulse", tags=["Anti-Impulse"])


@router.post("/start", response_model=AntiImpulseStartResponse, status_code=status.HTTP_201_CREATED)
async def start(data: AntiImpulseStartRequest, user: CurrentUser, db: DbSession):
    session = await start_session(db, user.id, data.planned_purchase_amount, data.category)
    return AntiImpulseStartResponse(
        session_id=session.id,
        risk_score=session.risk_score,
        cooldown_seconds=session.cooldown_seconds,
        goal_impact_days=session.goal_impact_days,
        recommended_intervention=getattr(session, "_intervention", "Take a moment to think."),
        message=f"Risk score: {session.risk_score}/100. Please wait {session.cooldown_seconds}s before deciding.",
    )


@router.post("/{session_id}/resolve", response_model=AntiImpulseSessionRead)
async def resolve(session_id: uuid.UUID, data: AntiImpulseResolveRequest, user: CurrentUser, db: DbSession):
    try:
        return await resolve_session(db, session_id, user.id, data.outcome)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get("/history", response_model=list[AntiImpulseSessionRead])
async def history(
    user: CurrentUser,
    db: DbSession,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=20, ge=1, le=100),
):
    result = await db.execute(
        select(AntiImpulseSession)
        .where(AntiImpulseSession.user_id == user.id)
        .order_by(AntiImpulseSession.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()
