import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.budget import BudgetCategoryLimit, BudgetPlan
from app.models.expense import Expense
from app.models.goal import Goal
from app.models.income import Income
from app.models.profile import UserProfile

ESSENTIALS_CATEGORIES = {"food", "transport", "health", "education"}
FUN_CATEGORIES = {"shopping", "entertainment", "subscriptions", "other"}

SEGMENT_ALLOCATIONS = {
    "student": {"essentials": Decimal("0.40"), "fun": Decimal("0.20"), "goals": Decimal("0.25"), "reserve": Decimal("0.15")},
    "freelancer": {"essentials": Decimal("0.35"), "fun": Decimal("0.20"), "goals": Decimal("0.25"), "reserve": Decimal("0.20")},
    "part_time": {"essentials": Decimal("0.40"), "fun": Decimal("0.20"), "goals": Decimal("0.25"), "reserve": Decimal("0.15")},
    "creator": {"essentials": Decimal("0.30"), "fun": Decimal("0.25"), "goals": Decimal("0.25"), "reserve": Decimal("0.20")},
}

STYLE_MODIFIERS = {
    "chaotic": {"fun": Decimal("0.05"), "reserve": Decimal("-0.05")},
    "medium": {"fun": Decimal("0"), "reserve": Decimal("0")},
    "disciplined": {"fun": Decimal("-0.05"), "goals": Decimal("0.05")},
}


async def _get_recent_income_total(db: AsyncSession, user_id: uuid.UUID, days: int = 30) -> Decimal:
    cutoff = datetime.now(UTC) - timedelta(days=days)
    result = await db.execute(
        select(func.coalesce(func.sum(Income.amount), 0)).where(and_(Income.user_id == user_id, Income.received_at >= cutoff))
    )
    return Decimal(str(result.scalar()))


async def generate_budget_plan(db: AsyncSession, user_id: uuid.UUID, period_type: str = "weekly") -> BudgetPlan:
    profile_result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    profile = profile_result.scalar_one_or_none()
    segment = profile.segment if profile else "student"
    style = profile.spending_style if profile else "medium"

    monthly_income = await _get_recent_income_total(db, user_id, days=30)
    if monthly_income == 0:
        monthly_income = Decimal("150000")

    if period_type == "weekly":
        period_income = monthly_income / 4
        today = date.today()
        weekday = today.weekday()
        period_start = today - timedelta(days=weekday)
        period_end = period_start + timedelta(days=6)
    else:
        period_income = monthly_income
        today = date.today()
        period_start = today.replace(day=1)
        next_month = today.replace(day=28) + timedelta(days=4)
        period_end = next_month - timedelta(days=next_month.day)

    alloc = dict(SEGMENT_ALLOCATIONS.get(segment, SEGMENT_ALLOCATIONS["student"]))
    modifiers = STYLE_MODIFIERS.get(style, STYLE_MODIFIERS["medium"])
    for key, mod in modifiers.items():
        if key in alloc:
            alloc[key] += mod

    existing = await db.execute(
        select(BudgetPlan).where(and_(BudgetPlan.user_id == user_id, BudgetPlan.is_active == True))
    )
    for old_plan in existing.scalars().all():
        old_plan.is_active = False

    plan = BudgetPlan(
        user_id=user_id,
        period_type=period_type,
        period_start=period_start,
        period_end=period_end,
        total_income_planned=period_income,
        essentials_planned=(period_income * alloc["essentials"]).quantize(Decimal("0.01")),
        fun_spending_planned=(period_income * alloc["fun"]).quantize(Decimal("0.01")),
        goal_contribution_planned=(period_income * alloc["goals"]).quantize(Decimal("0.01")),
        reserve_planned=(period_income * alloc["reserve"]).quantize(Decimal("0.01")),
        is_active=True,
    )
    db.add(plan)
    await db.flush()

    for cat in ESSENTIALS_CATEGORIES:
        share = plan.essentials_planned / len(ESSENTIALS_CATEGORIES)
        db.add(BudgetCategoryLimit(budget_plan_id=plan.id, category=cat, limit_amount=share.quantize(Decimal("0.01"))))

    for cat in FUN_CATEGORIES:
        share = plan.fun_spending_planned / len(FUN_CATEGORIES)
        db.add(BudgetCategoryLimit(budget_plan_id=plan.id, category=cat, limit_amount=share.quantize(Decimal("0.01"))))

    await db.flush()

    result = await db.execute(
        select(BudgetPlan).options(selectinload(BudgetPlan.category_limits)).where(BudgetPlan.id == plan.id)
    )
    return result.scalar_one()


async def get_active_budget(db: AsyncSession, user_id: uuid.UUID) -> BudgetPlan | None:
    result = await db.execute(
        select(BudgetPlan).options(selectinload(BudgetPlan.category_limits)).where(and_(BudgetPlan.user_id == user_id, BudgetPlan.is_active == True))
    )
    return result.scalar_one_or_none()


async def get_safe_to_spend(db: AsyncSession, user_id: uuid.UUID) -> dict:
    plan = await get_active_budget(db, user_id)
    if not plan:
        return {
            "safe_to_spend_today": 0,
            "remaining_fun_budget": 0,
            "remaining_days": 0,
            "status": "risk",
            "warnings": ["No active budget plan. Generate one first."],
        }

    today = date.today()
    period_start_dt = datetime.combine(plan.period_start, datetime.min.time()).replace(tzinfo=UTC)
    period_end_dt = datetime.combine(plan.period_end, datetime.max.time()).replace(tzinfo=UTC)

    fun_spent_result = await db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(
            and_(
                Expense.user_id == user_id,
                Expense.spent_at >= period_start_dt,
                Expense.spent_at <= period_end_dt,
                Expense.category.in_(FUN_CATEGORIES),
            )
        )
    )
    fun_spent = Decimal(str(fun_spent_result.scalar()))

    essential_spent_result = await db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(
            and_(
                Expense.user_id == user_id,
                Expense.spent_at >= period_start_dt,
                Expense.spent_at <= period_end_dt,
                Expense.category.in_(ESSENTIALS_CATEGORIES),
            )
        )
    )
    essential_spent = Decimal(str(essential_spent_result.scalar()))

    remaining_fun = max(Decimal("0"), plan.fun_spending_planned - fun_spent)
    remaining_days = max(1, (plan.period_end - today).days + 1)
    safe_today = float((remaining_fun / remaining_days).quantize(Decimal("0.01")))

    warnings = []
    if essential_spent > plan.essentials_planned:
        warnings.append(f"Essentials overspent by {essential_spent - plan.essentials_planned:.0f}")
    if fun_spent > plan.fun_spending_planned * Decimal("0.8"):
        warnings.append("Fun budget nearly exhausted for this period")

    if fun_spent > plan.fun_spending_planned:
        status = "risk"
    elif warnings:
        status = "warning"
    else:
        status = "good"

    return {
        "safe_to_spend_today": safe_today,
        "remaining_fun_budget": float(remaining_fun),
        "remaining_days": remaining_days,
        "status": status,
        "warnings": warnings,
    }


async def get_budget_health(db: AsyncSession, user_id: uuid.UUID) -> dict:
    plan = await get_active_budget(db, user_id)
    if not plan:
        return {"status": "risk", "score": 0, "reasons": ["No budget plan"], "recommendations": ["Create a budget plan"]}

    safe_data = await get_safe_to_spend(db, user_id)
    reasons = []
    recommendations = []
    score = 100

    if safe_data["status"] == "risk":
        score -= 40
        reasons.append("Fun budget exhausted")
        recommendations.append("Try to avoid non-essential spending for the rest of the period")
    elif safe_data["status"] == "warning":
        score -= 20
        reasons.append("Budget under pressure")
        recommendations.append("Be mindful of spending in the remaining days")

    for w in safe_data["warnings"]:
        score -= 10
        reasons.append(w)

    score = max(0, min(100, score))
    if score >= 70:
        status = "good"
    elif score >= 40:
        status = "warning"
    else:
        status = "risk"

    if not recommendations:
        recommendations.append("You're on track! Keep it up 💪")

    return {"status": status, "score": score, "reasons": reasons, "recommendations": recommendations}
