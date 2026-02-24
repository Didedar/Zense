from fastapi import APIRouter, HTTPException, status

from app.core.deps import CurrentUser, DbSession
from app.schemas.budget import (
    BudgetGenerateRequest,
    BudgetHealthCheck,
    BudgetPlanRead,
    BudgetPlanUpdate,
    SafeToSpendResponse,
)
from app.services.budget_service import generate_budget_plan, get_active_budget, get_budget_health, get_safe_to_spend

router = APIRouter(prefix="/budgets", tags=["Budgets"])


@router.post("/plan/generate", response_model=BudgetPlanRead, status_code=status.HTTP_201_CREATED)
async def generate_plan(data: BudgetGenerateRequest, user: CurrentUser, db: DbSession):
    plan = await generate_budget_plan(db, user.id, data.period_type)
    return plan


@router.get("/current", response_model=BudgetPlanRead)
async def get_current(user: CurrentUser, db: DbSession):
    plan = await get_active_budget(db, user.id)
    if not plan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No active budget plan")
    return plan


@router.patch("/current", response_model=BudgetPlanRead)
async def update_current(data: BudgetPlanUpdate, user: CurrentUser, db: DbSession):
    plan = await get_active_budget(db, user.id)
    if not plan:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No active budget plan")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(plan, field, value)
    await db.flush()
    return plan


@router.get("/safe-to-spend/today", response_model=SafeToSpendResponse)
async def safe_to_spend_today(user: CurrentUser, db: DbSession):
    return await get_safe_to_spend(db, user.id)


@router.get("/health-check", response_model=BudgetHealthCheck)
async def health_check(user: CurrentUser, db: DbSession):
    return await get_budget_health(db, user.id)
