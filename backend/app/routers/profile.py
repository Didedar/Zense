from decimal import Decimal
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.core.deps import CurrentUser, DbSession
from app.models.profile import UserProfile
from app.schemas.profile import OnboardingComplete, OnboardingResult, ProfileRead, ProfileUpdate
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


@router.post("/onboarding/complete", response_model=OnboardingResult)
async def complete_onboarding(data: OnboardingComplete, user: CurrentUser, db: DbSession):
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user.id))
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found")

    profile.segment = data.segment
    profile.spending_style = data.spending_style
    profile.onboarding_completed = True
    await db.flush()

    plan = await generate_budget_plan(db, user.id, "weekly")
    safe = await get_safe_to_spend(db, user.id)

    weekly_income = Decimal(str(data.monthly_income)) / 4

    budget_rec = {
        "period": "weekly",
        "total_income": float(weekly_income),
        "essentials": float(plan.essentials_planned),
        "fun": float(plan.fun_spending_planned),
        "goals": float(plan.goal_contribution_planned),
        "reserve": float(plan.reserve_planned),
    }

    actions = [
        "Add your first income source",
        "Set up your savings goals",
        "Track your first expense",
    ]
    if data.spending_style == "chaotic":
        actions.insert(0, "Enable anti-impulse protection")

    return OnboardingResult(
        budget_recommendation=budget_rec,
        safe_to_spend_today=safe["safe_to_spend_today"],
        first_actions=actions,
    )


@router.post("/onboarding/initial-plan", response_model=OnboardingResult)
async def initial_plan(data: OnboardingComplete, user: CurrentUser, db: DbSession):
    return await complete_onboarding(data, user, db)
