from decimal import Decimal
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.deps import CurrentUser, DbSession
from app.models.profile import UserProfile
from app.schemas.profile import ProfileRead, ProfileUpdate
from app.services.budget_service import generate_budget_plan, get_safe_to_spend

router = APIRouter(tags=["Profile"])


@router.get("/profile", response_model=ProfileRead)
async def get_profile(user: CurrentUser, db: DbSession):
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user.id))
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")
    return profile


@router.patch("/profile", response_model=ProfileRead)
async def update_profile(data: ProfileUpdate, user: CurrentUser, db: DbSession):
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user.id))
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")

    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    await db.flush()
    return profile

