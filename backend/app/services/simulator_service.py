import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.budget import BudgetPlan
from app.models.goal import Goal
from app.services.budget_service import get_safe_to_spend


async def calculate_purchase_impact(
    db: AsyncSession, user_id: uuid.UUID, purchase_amount: Decimal, category: str, planned_date: date | None = None
) -> dict:
    safe_data = await get_safe_to_spend(db, user_id)
    safe_today = Decimal(str(safe_data["safe_to_spend_today"]))
    is_safe = purchase_amount <= safe_today

    plan_result = await db.execute(
        select(BudgetPlan).where(and_(BudgetPlan.user_id == user_id, BudgetPlan.is_active == True))
    )
    plan = plan_result.scalar_one_or_none()

    budget_impact = {
        "remaining_fun_after": max(0, safe_data["remaining_fun_budget"] - float(purchase_amount)),
        "budget_utilization_pct": 0,
    }
    if plan and plan.fun_spending_planned > 0:
        budget_impact["budget_utilization_pct"] = round(float(purchase_amount) / float(plan.fun_spending_planned) * 100, 1)

    goals_result = await db.execute(
        select(Goal).where(and_(Goal.user_id == user_id, Goal.status == "active"))
    )
    goals = goals_result.scalars().all()

    goal_impacts = []
    for goal in goals:
        remaining = goal.target_amount - goal.current_amount
        if remaining <= 0:
            continue

        weekly_contribution = Decimal("0")
        if plan and plan.goal_contribution_planned > 0:
            active_goals_count = len([g for g in goals if g.target_amount > g.current_amount])
            weekly_contribution = plan.goal_contribution_planned / max(1, active_goals_count)

        if weekly_contribution > 0:
            shift_weeks = purchase_amount / weekly_contribution
            shift_days = int((shift_weeks * 7).quantize(Decimal("1")))
        else:
            shift_days = 0

        new_eta = None
        if goal.target_date:
            new_eta = goal.target_date + timedelta(days=shift_days)

        goal_impacts.append({
            "goal_id": str(goal.id),
            "goal_title": goal.title,
            "eta_shift_days": shift_days,
            "new_estimated_date": new_eta.isoformat() if new_eta else None,
        })

    if not is_safe and float(purchase_amount) > safe_data["remaining_fun_budget"]:
        recommendation = "postpone"
        reasoning = (
            f"This purchase of {purchase_amount:,.0f} exceeds your safe-to-spend "
            f"({safe_today:,.0f}) and remaining fun budget ({safe_data['remaining_fun_budget']:,.0f}). "
            f"Consider waiting until next period or finding a cheaper alternative."
        )
    elif not is_safe:
        recommendation = "reduce"
        reasoning = (
            f"The amount ({purchase_amount:,.0f}) is above today's safe-to-spend ({safe_today:,.0f}), "
            f"but within your period budget. Try reducing the amount or splitting the purchase."
        )
    elif goal_impacts and any(g["eta_shift_days"] > 7 for g in goal_impacts):
        recommendation = "split"
        reasoning = (
            f"You can afford this today, but it would delay your goals significantly. "
            f"Consider splitting into smaller purchases over multiple periods."
        )
    else:
        recommendation = "buy_now"
        reasoning = "This purchase fits within your budget and has minimal impact on your goals. Go for it! ✅"

    return {
        "is_safe_now": is_safe,
        "safe_to_spend_today": float(safe_today),
        "budget_impact": budget_impact,
        "goal_impacts": goal_impacts,
        "recommendation": recommendation,
        "reasoning": reasoning,
    }
