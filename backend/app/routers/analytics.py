from datetime import UTC, datetime, timedelta

from fastapi import APIRouter
from sqlalchemy import func, select

from app.core.deps import CurrentUser, DbSession
from app.models.app_event import AppEvent
from app.models.budget import BudgetPlan
from app.models.expense import Expense
from app.models.goal import Goal
from app.models.income import Income
from app.models.user import User
from app.schemas.analytics import DashboardSummary, TrackEventRequest

router = APIRouter(tags=["Analytics"])


@router.post("/events/track", status_code=201)
async def track_event(data: TrackEventRequest, user: CurrentUser, db: DbSession):
    event = AppEvent(user_id=user.id, event_name=data.event_name, event_payload=data.event_payload)
    db.add(event)
    await db.flush()
    return {"id": str(event.id), "tracked": True}


@router.get("/analytics/dashboard/summary", response_model=DashboardSummary)
async def dashboard_summary(user: CurrentUser, db: DbSession):
    total_users = (await db.execute(select(func.count()).select_from(User))).scalar()
    total_income = float((await db.execute(select(func.coalesce(func.sum(Income.amount), 0)).where(Income.user_id == user.id))).scalar())
    total_expenses = float((await db.execute(select(func.coalesce(func.sum(Expense.amount), 0)).where(Expense.user_id == user.id))).scalar())
    total_goals = (await db.execute(select(func.count()).where(Goal.user_id == user.id))).scalar()
    active_budgets = (await db.execute(select(func.count()).where(BudgetPlan.user_id == user.id, BudgetPlan.is_active == True))).scalar()

    week_ago = datetime.now(UTC) - timedelta(days=7)
    events_7d = (await db.execute(select(func.count()).where(AppEvent.created_at >= week_ago))).scalar()

    return DashboardSummary(
        total_users=total_users,
        total_income=total_income,
        total_expenses=total_expenses,
        total_goals=total_goals,
        active_budgets=active_budgets,
        events_last_7_days=events_7d,
    )
