import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from dateutil.relativedelta import relativedelta

from app.models.budget import BudgetPlan
from app.models.expense import Expense
from app.models.goal import Goal
from app.models.income import Income
from app.models.profile import UserProfile

SEGMENT_ALLOCATIONS = {
    "student": {"flexible": Decimal("0.60"), "goals": Decimal("0.25"), "reserve": Decimal("0.15")},
    "freelancer": {"flexible": Decimal("0.55"), "goals": Decimal("0.25"), "reserve": Decimal("0.20")},
    "part_time": {"flexible": Decimal("0.60"), "goals": Decimal("0.25"), "reserve": Decimal("0.15")},
    "creator": {"flexible": Decimal("0.55"), "goals": Decimal("0.25"), "reserve": Decimal("0.20")},
}

STYLE_MODIFIERS = {
    "chaotic": {"flexible": Decimal("0.05"), "reserve": Decimal("-0.05")},
    "medium": {"flexible": Decimal("0"), "reserve": Decimal("0")},
    "disciplined": {"flexible": Decimal("-0.05"), "goals": Decimal("0.05")},
}


async def _get_available_liquidity(db: AsyncSession, user_id: uuid.UUID, exclude_expenses_since: datetime | None = None) -> Decimal:
    """MVP: Calculate available liquidity. Fallback to recent income if history is insufficient."""
    cutoff = datetime.now(UTC) - timedelta(days=30)
    
    income_res = await db.execute(
        select(func.coalesce(func.sum(Income.amount), 0)).where(and_(Income.user_id == user_id, Income.received_at >= cutoff))
    )
    inflows = Decimal(str(income_res.scalar()))
    
    expense_query = select(func.coalesce(func.sum(Expense.amount), 0)).where(and_(Expense.user_id == user_id, Expense.spent_at >= cutoff))
    if exclude_expenses_since:
        expense_query = expense_query.where(Expense.spent_at < exclude_expenses_since)
        
    expense_res = await db.execute(expense_query)
    outflows = Decimal(str(expense_res.scalar()))
    
    # MVP ledger approach
    available = inflows - outflows
    
    # Fallback to prevent 0 budget only if the user hasn't logged any income yet
    if inflows == Decimal("0"):
        return Decimal("20000")
        
    return max(Decimal("0"), available)


async def generate_budget_plan(db: AsyncSession, user_id: uuid.UUID, period_type: str = "weekly") -> BudgetPlan:
    profile_result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    profile = profile_result.scalar_one_or_none()
    segment = profile.segment if profile else "student"
    style = profile.spending_style if profile else "medium"

    # Убираем жесткую привязку к 1-му числу!
    today = date.today()
    period_start = today
    
    # Магия relativedelta: если сегодня 26 февраля, он автоматически 
    # сделает period_end = 26 марта (с учетом любого года).
    if period_type == "monthly":
        period_end = period_start + relativedelta(months=1)
    elif period_type == "weekly":
        period_end = period_start + relativedelta(weeks=1)
    else:
        # Fallback
        period_end = period_start + relativedelta(months=1)

    period_start_dt = datetime.combine(period_start, datetime.min.time()).replace(tzinfo=UTC)
    period_end_dt = datetime.combine(period_end, datetime.max.time()).replace(tzinfo=UTC)

    # Теперь мы высчитываем точное количество дней в ЭТОМ плавающем цикле
    total_days = (period_end - period_start).days

    # Top-Line Income
    monthly_base = await _get_available_liquidity(db, user_id, exclude_expenses_since=period_start_dt)

    # For a monthly budget, period income is exactly the monthly base
    period_income = monthly_base

    # Hard Commitments (is_fixed = True)
    fixed_res = await db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0))
        .where(
            and_(
                Expense.user_id == user_id,
                Expense.is_fixed == True,
                Expense.spent_at >= period_start_dt,
                Expense.spent_at <= period_end_dt,
            )
        )
    )
    hard_commitments = Decimal(str(fixed_res.scalar()))

    # Net Available
    net_available = max(Decimal("0"), period_income - hard_commitments)

    alloc = dict(SEGMENT_ALLOCATIONS.get(segment, SEGMENT_ALLOCATIONS["student"]))
    modifiers = STYLE_MODIFIERS.get(style, STYLE_MODIFIERS["medium"])
    for key, mod in modifiers.items():
        if key in alloc:
            alloc[key] += mod
            
    # Clamp to >= 0
    alloc = {k: max(Decimal("0"), v) for k, v in alloc.items()}

    # Normalize allocations to ensure they sum to exactly 1.0 (100%)
    total_alloc = sum(alloc.values())
    if total_alloc > 0:
        alloc = {k: v / total_alloc for k, v in alloc.items()}
    else:
        # Fallback if somehow all 0 or negative
        alloc = {"flexible": Decimal("0.5"), "goals": Decimal("0.3"), "reserve": Decimal("0.2")}

    reserve_pct = alloc.get("reserve", Decimal("0.0")).quantize(Decimal("0.0001"))
    goals_pct = alloc.get("goals", Decimal("0.0")).quantize(Decimal("0.0001"))
    free_pct = alloc.get("flexible", Decimal("0.0")).quantize(Decimal("0.0001"))

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
        top_line_income=period_income,
        hard_commitments_total=hard_commitments,
        net_available=net_available,
        reserve_pct=reserve_pct,
        goals_pct=goals_pct,
        free_pct=free_pct,
        flexible_planned=(net_available * alloc["flexible"]).quantize(Decimal("0.01")),
        free_money_planned=(net_available * alloc["flexible"]).quantize(Decimal("0.01")),
        goal_contribution_planned=(net_available * alloc["goals"]).quantize(Decimal("0.01")),
        reserve_planned=(net_available * alloc["reserve"]).quantize(Decimal("0.01")),
        is_active=True,
    )
    db.add(plan)
    await db.flush()

    result = await db.execute(
        select(BudgetPlan).where(BudgetPlan.id == plan.id)
    )
    return result.scalar_one()


async def get_active_budget(db: AsyncSession, user_id: uuid.UUID) -> BudgetPlan | None:
    result = await db.execute(
        select(BudgetPlan).where(and_(BudgetPlan.user_id == user_id, BudgetPlan.is_active == True))
    )
    return result.scalar_one_or_none()


async def get_safe_to_spend(db: AsyncSession, user_id: uuid.UUID) -> dict:
    plan = await get_active_budget(db, user_id)
    if not plan:
        return {
            "top_line_income": 0, "fixed_locked": 0, "net_available": 0, "free_limit": 0,
            "spent_variable": 0, "remaining_free": 0,
            "spending_limit": 0, "total_spent": 0, "fixed_spent": 0, "variable_spent": 0,
            "safe_to_spend_today": 0, "remaining_fun_budget": 0, "remaining_spending_budget": 0,
            "remaining_days": 0, "time_spent_pct": 0, "budget_spent_pct": 0, "burn_delta": 0,
            "status": "risk", "warnings": ["Нет активного бюджета. Сначала сгенерируйте его."], "borrow_options": []
        }

    today = date.today()
    period_start_dt = datetime.combine(plan.period_start, datetime.min.time()).replace(tzinfo=UTC)
    period_end_dt = datetime.combine(plan.period_end, datetime.max.time()).replace(tzinfo=UTC)
    today_start_dt = datetime.combine(today, datetime.min.time()).replace(tzinfo=UTC)

    # Spent Variable BEFORE today
    variable_before_today_res = await db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0))
        .where(
            and_(
                Expense.user_id == user_id,
                Expense.is_fixed == False,
                Expense.spent_at >= period_start_dt,
                Expense.spent_at < today_start_dt,
            )
        )
    )
    variable_before_today = Decimal(str(variable_before_today_res.scalar()))

    # Spent Variable TODAY and ONWARDS
    variable_today_res = await db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0))
        .where(
            and_(
                Expense.user_id == user_id,
                Expense.is_fixed == False,
                Expense.spent_at >= today_start_dt,
                Expense.spent_at <= period_end_dt,
            )
        )
    )
    variable_today = Decimal(str(variable_today_res.scalar()))
    
    variable_spent = variable_before_today + variable_today
    
    # Spent Fixed (just for reporting metrics)
    fixed_res = await db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0))
        .where(
            and_(
                Expense.user_id == user_id,
                Expense.is_fixed == True,
                Expense.spent_at >= period_start_dt,
                Expense.spent_at <= period_end_dt,
            )
        )
    )
    fixed_spent = Decimal(str(fixed_res.scalar()))

    total_spent = fixed_spent + variable_spent

    # Variable Limit and Remaining
    spending_limit = plan.free_money_planned if plan.free_money_planned > 0 else plan.flexible_planned
    remaining_budget = max(Decimal("0"), spending_limit - variable_spent)

    total_days = max(1, (plan.period_end - plan.period_start).days + 1)
    current_day_offset = (today - plan.period_start).days + 1
    elapsed_days = max(1, min(total_days, current_day_offset))
    # Сколько дней осталось жить на эти деньги (включая сегодняшний)
    remaining_days = max(1, total_days - elapsed_days + 1)
    
    # --- ИСПРАВЛЕННАЯ ФОРМУЛА SAFE-TO-SPEND (Вычитаем траты сегодня полностью из лимита сегодня) ---
    remaining_budget_before_today = max(Decimal("0"), spending_limit - variable_before_today)
    if remaining_budget_before_today <= 0:
        base_daily_limit = Decimal("0")
    else:
        # Размазываем реальный остаток на начало дня на оставшиеся дни
        base_daily_limit = remaining_budget_before_today / Decimal(remaining_days)
        
    safe_today_decimal = max(Decimal("0"), base_daily_limit - variable_today)
    safe_today = float(safe_today_decimal.quantize(Decimal("0.01")))

    # --- ИСПРАВЛЕННАЯ ФОРМУЛА BURN RATE (Темп трат) ---
    time_spent_pct = float(elapsed_days / total_days)
    
    # ВАЖНО: Сравниваем только переменные траты с лимитом на переменные траты!
    budget_spent_pct = float(variable_spent / spending_limit) if spending_limit > 0 else 1.0
    
    burn_delta = budget_spent_pct - time_spent_pct

    warnings = []
    status = "good"
    WARNING_DELTA = 0.15
    RISK_DELTA = 0.30
    
    if burn_delta > RISK_DELTA or total_spent > spending_limit:
        status = "risk"
        warnings.append("Критический перерасход: вы тратите деньги значительно быстрее, чем идет время.")
    elif burn_delta > WARNING_DELTA or total_spent > spending_limit * Decimal("0.9"):
        status = "warning"
        warnings.append("Внимание: темп трат опережает план. Рекомендуем снизить расходы.")

    # Fix 4: Self-Borrowing Suggestions
    borrow_options = []
    if status == "risk" or remaining_budget == 0:
        if plan.reserve_planned > 0:
            borrow_options.append({
                "source": "reserve",
                "amount": float(plan.reserve_planned),
                "message": f"Можно перенести {plan.reserve_planned} ₸ из резерва (без риска для целей)."
            })
        if plan.goal_contribution_planned > 0:
            borrow_options.append({
                "source": "goals",
                "amount": float(plan.goal_contribution_planned),
                "message": f"Можно задержать пополнение целей на {plan.goal_contribution_planned} ₸ в этом периоде."
            })

    return {
        "top_line_income": float(plan.top_line_income),
        "fixed_locked": float(plan.hard_commitments_total),
        "net_available": float(plan.net_available),
        "free_limit": float(spending_limit),
        "spent_variable": float(variable_spent),
        "remaining_free": float(remaining_budget),
        "spending_limit": float(spending_limit),
        "total_spent": float(total_spent),
        "fixed_spent": float(fixed_spent),
        "variable_spent": float(variable_spent),
        "safe_to_spend_today": safe_today,
        "remaining_fun_budget": float(remaining_budget),
        "remaining_spending_budget": float(remaining_budget),
        "remaining_days": remaining_days,
        "time_spent_pct": time_spent_pct,
        "budget_spent_pct": budget_spent_pct,
        "burn_delta": burn_delta,
        "status": status,
        "warnings": warnings,
        "borrow_options": borrow_options
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
        reasons.append("Ваш темп расходов сильно превышает норму.")
        if safe_data.get("borrow_options"):
            recommendations.append("Рассмотрите возможность использовать резервы: " + safe_data["borrow_options"][0]["message"])
        else:
            recommendations.append("Максимально сократите необязательные траты до конца периода.")
    elif safe_data["status"] == "warning":
        score -= 20
        reasons.append("Вы тратите быстрее, чем планировалось.")
        recommendations.append("Снизьте темп покупок в ближайшие дни.")

    for w in safe_data["warnings"]:
        score -= 10
        if w not in reasons:
            reasons.append(w)

    score = max(0, min(100, score))
    status = "good" if score >= 70 else ("warning" if score >= 40 else "risk")

    if not recommendations and status == "good":
        recommendations.append("Вы отлично справляетесь! Так держать 💪")

    return {"status": status, "score": score, "reasons": reasons, "recommendations": recommendations}
