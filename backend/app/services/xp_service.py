"""
XP Rules Engine — awards XP for financial actions.

Level formula: level = 1 + total_xp // 500
XP thresholds: 500 per level (linear for MVP)
"""

import uuid
from datetime import UTC, date, datetime

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.xp import UserXP, XPTransaction

# ── XP Rules ──
XP_RULES: dict[str, dict] = {
    "expense_logged": {"xp": 15, "desc": "Записал расход"},
    "income_logged": {"xp": 20, "desc": "Записал доход"},
    "goal_created": {"xp": 30, "desc": "Создал финансовую цель"},
    "goal_contribution": {"xp": 25, "desc": "Внёс на цель"},
    "goal_completed": {"xp": 200, "desc": "Достиг цели! 🎉"},
    "budget_generated": {"xp": 40, "desc": "Создал бюджет"},
    "anti_impulse_skipped": {"xp": 50, "desc": "Устоял перед импульсом 💪"},
    "anti_impulse_delayed": {"xp": 25, "desc": "Отложил покупку"},
    "simulator_used": {"xp": 15, "desc": "Использовал симулятор"},
    "coach_asked": {"xp": 10, "desc": "Спросил коуча"},
    "report_viewed": {"xp": 10, "desc": "Посмотрел отчёт"},
    "quest_completed": {"xp": 0, "desc": "Выполнил квест"},  # XP from quest itself
    "lesson_completed": {"xp": 0, "desc": "Прошёл микро-урок"},  # XP from lesson
    "streak_day": {"xp": 10, "desc": "Ежедневная серия"},
    "first_expense": {"xp": 50, "desc": "Первый расход записан! 🚀"},
    "first_income": {"xp": 50, "desc": "Первый доход записан! 🚀"},
    "first_goal": {"xp": 50, "desc": "Первая цель создана! 🚀"},
}

XP_PER_LEVEL = 500


def calculate_level(total_xp: int) -> int:
    return 1 + total_xp // XP_PER_LEVEL


def xp_to_next_level(total_xp: int) -> int:
    current_level = calculate_level(total_xp)
    return current_level * XP_PER_LEVEL - total_xp


def level_progress_percent(total_xp: int) -> float:
    xp_in_level = total_xp % XP_PER_LEVEL
    return round(xp_in_level / XP_PER_LEVEL * 100, 1)


async def get_or_create_user_xp(db: AsyncSession, user_id: uuid.UUID) -> UserXP:
    result = await db.execute(select(UserXP).where(UserXP.user_id == user_id))
    user_xp = result.scalar_one_or_none()
    if not user_xp:
        user_xp = UserXP(user_id=user_id, total_xp=0, level=1, streak_days=0)
        db.add(user_xp)
        await db.flush()
    return user_xp


async def award_xp(
    db: AsyncSession,
    user_id: uuid.UUID,
    action: str,
    source_id: str | None = None,
    override_xp: int | None = None,
) -> dict:
    rule = XP_RULES.get(action)
    if not rule and override_xp is None:
        return {"xp_awarded": 0, "total_xp": 0, "level": 1, "leveled_up": False, "message": "Unknown action"}

    xp_amount = override_xp if override_xp is not None else rule["xp"]
    desc = rule["desc"] if rule else action

    if xp_amount == 0 and override_xp is None:
        user_xp = await get_or_create_user_xp(db, user_id)
        return {
            "xp_awarded": 0,
            "total_xp": user_xp.total_xp,
            "level": user_xp.level,
            "leveled_up": False,
            "message": desc,
        }

    user_xp = await get_or_create_user_xp(db, user_id)
    old_level = user_xp.level

    # Update streak
    today = date.today()
    if user_xp.last_action_date:
        last_date = user_xp.last_action_date.date() if isinstance(user_xp.last_action_date, datetime) else user_xp.last_action_date
        days_diff = (today - last_date).days
        if days_diff == 1:
            user_xp.streak_days += 1
            # Bonus XP for streak milestones
            if user_xp.streak_days % 7 == 0:
                xp_amount += 50  # Weekly streak bonus
        elif days_diff > 1:
            user_xp.streak_days = 1
    else:
        user_xp.streak_days = 1

    user_xp.total_xp += xp_amount
    user_xp.level = calculate_level(user_xp.total_xp)
    user_xp.last_action_date = datetime.now(UTC)

    tx = XPTransaction(
        user_id=user_id,
        action=action,
        xp_amount=xp_amount,
        description=desc,
        source_id=source_id,
    )
    db.add(tx)
    await db.flush()

    leveled_up = user_xp.level > old_level

    return {
        "xp_awarded": xp_amount,
        "total_xp": user_xp.total_xp,
        "level": user_xp.level,
        "leveled_up": leveled_up,
        "message": f"+{xp_amount} XP: {desc}" + (" 🎉 Новый уровень!" if leveled_up else ""),
    }


async def get_xp_overview(db: AsyncSession, user_id: uuid.UUID) -> dict:
    user_xp = await get_or_create_user_xp(db, user_id)
    return {
        "total_xp": user_xp.total_xp,
        "level": user_xp.level,
        "streak_days": user_xp.streak_days,
        "xp_to_next_level": xp_to_next_level(user_xp.total_xp),
        "level_progress_percent": level_progress_percent(user_xp.total_xp),
        "last_action_date": user_xp.last_action_date,
    }


async def get_xp_history(db: AsyncSession, user_id: uuid.UUID, limit: int = 50) -> list:
    result = await db.execute(
        select(XPTransaction)
        .where(XPTransaction.user_id == user_id)
        .order_by(XPTransaction.created_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())


async def check_first_time_bonus(db: AsyncSession, user_id: uuid.UUID, action: str) -> bool:
    """Check if this is the first time a user performs a certain action."""
    first_actions = {
        "expense_logged": "first_expense",
        "income_logged": "first_income",
        "goal_created": "first_goal",
    }
    bonus_action = first_actions.get(action)
    if not bonus_action:
        return False

    existing = await db.execute(
        select(func.count()).where(
            and_(XPTransaction.user_id == user_id, XPTransaction.action == bonus_action)
        )
    )
    if existing.scalar() == 0:
        await award_xp(db, user_id, bonus_action)
        return True
    return False
