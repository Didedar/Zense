import uuid
from datetime import UTC, datetime, timedelta
from decimal import Decimal

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.anti_impulse import AntiImpulseSession
from app.models.expense import Expense
from app.services.budget_service import get_safe_to_spend
from app.services.simulator_service import calculate_purchase_impact

HIGH_RISK_CATEGORIES = {"shopping", "entertainment"}
LATE_HOUR_THRESHOLD = 22
REPEAT_WINDOW_HOURS = 48


async def calculate_risk_score(
    db: AsyncSession, user_id: uuid.UUID, amount: Decimal, category: str
) -> tuple[int, int, str]:
    score = 0
    reasons = []

    if category in HIGH_RISK_CATEGORIES:
        score += 25
        reasons.append("high-risk category")

    safe_data = await get_safe_to_spend(db, user_id)
    safe_today = Decimal(str(safe_data["safe_to_spend_today"]))
    if amount > safe_today:
        score += 30
        reasons.append("exceeds safe-to-spend")
    elif amount > safe_today * Decimal("0.7"):
        score += 15
        reasons.append("uses most of safe-to-spend")

    now = datetime.now(UTC)
    if now.hour >= LATE_HOUR_THRESHOLD:
        score += 15
        reasons.append("late-night purchase")

    cutoff = now - timedelta(hours=REPEAT_WINDOW_HOURS)
    repeat_result = await db.execute(
        select(func.count()).where(
            and_(Expense.user_id == user_id, Expense.category == category, Expense.spent_at >= cutoff)
        )
    )
    repeat_count = repeat_result.scalar()
    if repeat_count and repeat_count >= 2:
        score += 20
        reasons.append(f"repeat purchase in {category} ({repeat_count} in 48h)")

    score = min(100, score)

    if score >= 70:
        cooldown = 120
        intervention = "We suggest a 2-minute pause. Take a deep breath and reconsider if this is a need or a want."
    elif score >= 40:
        cooldown = 60
        intervention = "Take a moment — 1 minute — to think about whether this aligns with your goals."
    else:
        cooldown = 30
        intervention = "Quick check: does this purchase feel right? You're good, just making sure."

    return score, cooldown, intervention


async def start_session(
    db: AsyncSession, user_id: uuid.UUID, amount: Decimal, category: str
) -> AntiImpulseSession:
    risk_score, cooldown, intervention = await calculate_risk_score(db, user_id, amount, category)

    impact = await calculate_purchase_impact(db, user_id, amount, category)
    goal_impact_days = None
    if impact["goal_impacts"]:
        goal_impact_days = max(g["eta_shift_days"] for g in impact["goal_impacts"])

    session = AntiImpulseSession(
        user_id=user_id,
        planned_purchase_amount=amount,
        category=category,
        goal_impact_days=goal_impact_days,
        risk_score=risk_score,
        cooldown_seconds=cooldown,
        outcome="pending",
    )
    db.add(session)
    await db.flush()

    session._intervention = intervention
    return session


async def resolve_session(
    db: AsyncSession, session_id: uuid.UUID, user_id: uuid.UUID, outcome: str
) -> AntiImpulseSession:
    result = await db.execute(
        select(AntiImpulseSession).where(
            and_(AntiImpulseSession.id == session_id, AntiImpulseSession.user_id == user_id)
        )
    )
    session = result.scalar_one_or_none()
    if not session:
        raise ValueError("Session not found")

    valid_outcomes = {"bought", "postponed", "cancelled", "ignored"}
    if outcome not in valid_outcomes:
        raise ValueError(f"Invalid outcome. Must be one of: {valid_outcomes}")

    session.outcome = outcome
    session.resolved_at = datetime.now(UTC)
    await db.flush()
    return session
