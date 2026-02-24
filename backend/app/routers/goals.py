import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import and_, func, select

from app.core.deps import CurrentUser, DbSession
from app.models.goal import Goal
from app.models.goal_contribution import GoalContribution
from app.schemas.goal import GoalContributeRequest, GoalCreate, GoalProgress, GoalRead, GoalUpdate

router = APIRouter(prefix="/goals", tags=["Goals"])


@router.post("/", response_model=GoalRead, status_code=status.HTTP_201_CREATED)
async def create_goal(data: GoalCreate, user: CurrentUser, db: DbSession):
    goal = Goal(user_id=user.id, **data.model_dump())
    db.add(goal)
    await db.flush()
    return goal


@router.get("/", response_model=list[GoalRead])
async def list_goals(user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(Goal).where(Goal.user_id == user.id).order_by(Goal.priority.asc(), Goal.created_at.desc())
    )
    return result.scalars().all()


@router.get("/{goal_id}", response_model=GoalRead)
async def get_goal(goal_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(select(Goal).where(and_(Goal.id == goal_id, Goal.user_id == user.id)))
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
    return goal


@router.patch("/{goal_id}", response_model=GoalRead)
async def update_goal(goal_id: uuid.UUID, data: GoalUpdate, user: CurrentUser, db: DbSession):
    result = await db.execute(select(Goal).where(and_(Goal.id == goal_id, Goal.user_id == user.id)))
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(goal, field, value)
    await db.flush()
    return goal


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(goal_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(select(Goal).where(and_(Goal.id == goal_id, Goal.user_id == user.id)))
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
    await db.delete(goal)


@router.post("/{goal_id}/contribute", response_model=GoalRead)
async def contribute_to_goal(goal_id: uuid.UUID, data: GoalContributeRequest, user: CurrentUser, db: DbSession):
    result = await db.execute(select(Goal).where(and_(Goal.id == goal_id, Goal.user_id == user.id)))
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
    if goal.status != "active":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Goal is not active")

    goal.current_amount += data.amount
    if goal.current_amount >= goal.target_amount:
        goal.status = "completed"

    contribution = GoalContribution(
        user_id=user.id,
        goal_id=goal.id,
        amount=data.amount,
        contributed_at=datetime.now(UTC),
        source=data.source,
        note=data.note,
    )
    db.add(contribution)
    await db.flush()
    return goal


@router.get("/{goal_id}/progress", response_model=GoalProgress)
async def get_goal_progress(goal_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(select(Goal).where(and_(Goal.id == goal_id, Goal.user_id == user.id)))
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")

    remaining = goal.target_amount - goal.current_amount
    pct = float(goal.current_amount / goal.target_amount * 100) if goal.target_amount > 0 else 0

    days_remaining = None
    weekly_needed = None
    estimated_date = None

    if goal.target_date:
        days_remaining = max(0, (goal.target_date - date.today()).days)
        weeks_remaining = max(1, days_remaining / 7)
        weekly_needed = (remaining / Decimal(str(weeks_remaining))).quantize(Decimal("0.01")) if remaining > 0 else Decimal("0")
    else:
        last_30_result = await db.execute(
            select(func.coalesce(func.sum(GoalContribution.amount), 0)).where(
                and_(
                    GoalContribution.goal_id == goal.id,
                    GoalContribution.contributed_at >= datetime.now(UTC) - timedelta(days=30),
                )
            )
        )
        monthly_rate = Decimal(str(last_30_result.scalar()))
        if monthly_rate > 0:
            weeks_to_go = float(remaining / monthly_rate * Decimal("4.33"))
            estimated_date = date.today() + timedelta(weeks=weeks_to_go)
            weekly_needed = (monthly_rate / Decimal("4.33")).quantize(Decimal("0.01"))
            days_remaining = int(weeks_to_go * 7)

    return GoalProgress(
        goal_id=goal.id,
        title=goal.title,
        target_amount=goal.target_amount,
        current_amount=goal.current_amount,
        remaining=remaining,
        percent_complete=round(pct, 1),
        days_remaining=days_remaining,
        estimated_completion_date=estimated_date,
        weekly_contribution_needed=weekly_needed,
    )
