import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from fastapi import APIRouter, HTTPException, status
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, DbSession
from app.models.goal import Goal
from app.models.goal_contribution import GoalContribution
from app.models.budget import BudgetPlan
from app.models.expense import Expense
from app.schemas.goal import GoalContributeRequest, GoalCreate, GoalProgress, GoalRead, GoalUpdate
from app.services.xp_service import award_xp, check_first_time_bonus
from app.services.quest_service import update_quest_progress
from app.services.notification_service import fire_notification_rule
from app.services.budget_service import get_active_budget, get_safe_to_spend

router = APIRouter(prefix="/goals", tags=["Goals"])

async def check_and_apply_auto_funding(db: AsyncSession, user_id: uuid.UUID, goal: Goal):
    if goal.status != "active":
        return goal

    today = date.today()
    plan = await get_active_budget(db, user_id)
    if not plan or plan.goal_contribution_planned <= 0:
        goal.last_auto_funded_date = today
        return goal
        
    last_funded = goal.last_auto_funded_date or plan.period_start
    if last_funded >= today or today < plan.period_start:
        return goal
        
    delta_days = (today - last_funded).days
    if delta_days <= 0:
        return goal
        
    days_in_period = max(1, (plan.period_end - plan.period_start).days + 1)
    daily_goal_budget = plan.goal_contribution_planned / Decimal(str(days_in_period))
    
    # Calculate amount to fund based on delta days
    amount_to_fund = (daily_goal_budget * Decimal(str(delta_days))).quantize(Decimal("0.01"))
    
    # Do not exceed goals_planned for the period (assuming this is a cumulative cap for now)
    # To truly enforce "no more than what's left in the plan", we would track total auto-funded 
    # for the period, but for MVP we cap it at the total planned amount minus current amount.
    amount_to_fund = min(amount_to_fund, plan.goal_contribution_planned)
    
    if amount_to_fund > 0:
        goal.current_amount += amount_to_fund
        plan.goal_contribution_planned = max(Decimal("0"), plan.goal_contribution_planned - amount_to_fund)
        if goal.current_amount >= goal.target_amount:
            goal.status = "completed"
            
        contribution = GoalContribution(
            user_id=user_id,
            goal_id=goal.id,
            amount=amount_to_fund,
            contributed_at=datetime.now(UTC),
            source="auto_plan",
            note=f"Auto-funded for {delta_days} days",
        )
        db.add(contribution)
        
    goal.last_auto_funded_date = today
    await db.flush()
    return goal


@router.post("", response_model=GoalRead, status_code=status.HTTP_201_CREATED)
async def create_goal(data: GoalCreate, user: CurrentUser, db: DbSession):
    goal = Goal(user_id=user.id, **data.model_dump())
    db.add(goal)
    await db.flush()

    try:
        async with db.begin_nested():
            await award_xp(db, user.id, "goal_created", source_id=str(goal.id))
            await check_first_time_bonus(db, user.id, "goal_created")
            await update_quest_progress(db, user.id, "goal_created")
    except Exception:
        pass

    return goal


@router.get("", response_model=list[GoalRead])
async def list_goals(user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(Goal).where(Goal.user_id == user.id).order_by(Goal.priority.asc(), Goal.created_at.desc())
    )
    goals = result.scalars().all()
    for goal in goals:
        await check_and_apply_auto_funding(db, user.id, goal)
    return goals


@router.get("/{goal_id}", response_model=GoalRead)
async def get_goal(goal_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(select(Goal).where(and_(Goal.id == goal_id, Goal.user_id == user.id)))
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
        
    goal = await check_and_apply_auto_funding(db, user.id, goal)
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

    plan = await get_active_budget(db, user.id)
    if plan:
        plan.goal_contribution_planned = max(Decimal("0"), plan.goal_contribution_planned - data.amount)

    goal.current_amount += data.amount
    was_completed = False
    if goal.current_amount >= goal.target_amount:
        goal.status = "completed"
        was_completed = True

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

    try:
        async with db.begin_nested():
            await award_xp(db, user.id, "goal_contribution", source_id=str(goal.id))
            await update_quest_progress(db, user.id, "goal_contribution")
            if was_completed:
                await award_xp(db, user.id, "goal_completed", source_id=str(goal.id))
                await update_quest_progress(db, user.id, "goal_completed")
                await fire_notification_rule(db, user.id, "goal_progress", {"goal_title": goal.title, "percent": 100})
            else:
                pct = float(goal.current_amount / goal.target_amount * 100) if goal.target_amount > 0 else 0
                if pct >= 50 and pct - float(data.amount / goal.target_amount * 100) < 50:
                    await fire_notification_rule(db, user.id, "goal_progress", {"goal_title": goal.title, "percent": int(pct)})
    except Exception:
        pass

    return goal


@router.post("/{goal_id}/fund", response_model=GoalRead)
async def fund_goal_waterfall(goal_id: uuid.UUID, data: GoalContributeRequest, user: CurrentUser, db: DbSession):
    """
    Manual Funding using the Waterfall Method:
    Step A: Try to pull from `Remaining` liquidity.
    Step B: If insufficient, pull the rest from `Reserve`.
    Step C: If `Reserve` is also insufficient, reject.
    """
    result = await db.execute(select(Goal).where(and_(Goal.id == goal_id, Goal.user_id == user.id)))
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
    if goal.status != "active":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Goal is not active")

    safe_data = await get_safe_to_spend(db, user.id)
    remaining_free = Decimal(str(safe_data["remaining_free"]))
    
    plan = await get_active_budget(db, user_id)
    if not plan:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No active budget plan found.")

    amount_needed = data.amount
    amount_from_free = Decimal("0")
    amount_from_reserve = Decimal("0")

    # Step A: Pull from Free Money (Remaining Free)
    if remaining_free >= amount_needed:
        amount_from_free = amount_needed
        amount_needed = Decimal("0")
    else:
        amount_from_free = remaining_free
        amount_needed -= remaining_free

    # Step B: Pull rest from Reserve
    if amount_needed > 0:
        if plan.reserve_planned >= amount_needed:
            amount_from_reserve = amount_needed
            amount_needed = Decimal("0")
        else:
            # Step C: Total Failure
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, 
                detail=f"Недостаточно средств. Свободно: {remaining_free} ₸, Резерв: {plan.reserve_planned} ₸."
            )

    # Apply pulling from Free (simulated by creating a variable expense)
    if amount_from_free > 0:
        db.add(Expense(
            user_id=user.id,
            amount=amount_from_free,
            category="goal_funding",
            spent_at=datetime.now(UTC),
            note=f"Manual funding for goal: {goal.title}",
            is_fixed=False,
            expense_kind="variable"
        ))

    # Apply pulling from Reserve (deducting from plan directly)
    if amount_from_reserve > 0:
        plan.reserve_planned -= amount_from_reserve

    # Apply to Goal
    goal.current_amount += data.amount
    was_completed = False
    if goal.current_amount >= goal.target_amount:
        goal.status = "completed"
        was_completed = True

    contribution = GoalContribution(
        user_id=user.id,
        goal_id=goal.id,
        amount=data.amount,
        contributed_at=datetime.now(UTC),
        source="manual_waterfall",
        note=data.note,
    )
    db.add(contribution)
    await db.flush()

    try:
        async with db.begin_nested():
            await award_xp(db, user.id, "goal_contribution", source_id=str(goal.id))
            await update_quest_progress(db, user.id, "goal_contribution")
            if was_completed:
                await award_xp(db, user.id, "goal_completed", source_id=str(goal.id))
                await update_quest_progress(db, user.id, "goal_completed")
                await fire_notification_rule(db, user.id, "goal_progress", {"goal_title": goal.title, "percent": 100})
            else:
                pct = float(goal.current_amount / goal.target_amount * 100) if goal.target_amount > 0 else 0
                if pct >= 50 and pct - float(data.amount / goal.target_amount * 100) < 50:
                    await fire_notification_rule(db, user.id, "goal_progress", {"goal_title": goal.title, "percent": int(pct)})
    except Exception:
        pass

    return goal


@router.get("/{goal_id}/progress", response_model=GoalProgress)
async def get_goal_progress(goal_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(select(Goal).where(and_(Goal.id == goal_id, Goal.user_id == user.id)))
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Goal not found")
        
    goal = await check_and_apply_auto_funding(db, user.id, goal)

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
