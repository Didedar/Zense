"""
Micro-Lesson Service — triggers contextual lessons based on user behavior.
"""

import uuid
from datetime import UTC, datetime, timedelta

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.micro_lesson import MicroLesson, UserLessonHistory
from app.services.xp_service import award_xp


async def check_trigger(db: AsyncSession, user_id: uuid.UUID, event: str, context: dict | None = None) -> dict | None:
    """Check if a micro-lesson should be triggered for this event."""
    # Find lessons matching this trigger event
    result = await db.execute(
        select(MicroLesson).where(
            and_(MicroLesson.trigger_event == event, MicroLesson.is_active == True)
        )
    )
    candidates = result.scalars().all()

    if not candidates:
        return None

    # Filter out recently shown lessons (cooldown: 24 hours)
    cooldown = datetime.now(UTC) - timedelta(hours=24)
    recently_shown = await db.execute(
        select(UserLessonHistory.lesson_id).where(
            and_(
                UserLessonHistory.user_id == user_id,
                UserLessonHistory.shown_at >= cooldown,
            )
        )
    )
    recent_ids = {row[0] for row in recently_shown.all()}

    for lesson in candidates:
        if lesson.id in recent_ids:
            continue

        # Check conditions against context
        if lesson.trigger_conditions and context:
            if not _evaluate_conditions(lesson.trigger_conditions, context):
                continue

        # Record that we showed this lesson
        history = UserLessonHistory(user_id=user_id, lesson_id=lesson.id)
        db.add(history)
        await db.flush()

        return {
            "lesson": {
                "id": str(lesson.id),
                "slug": lesson.slug,
                "title": lesson.title,
                "body": lesson.body,
                "category": lesson.category,
                "icon_emoji": lesson.icon_emoji,
                "xp_reward": lesson.xp_reward,
                "duration_seconds": lesson.duration_seconds,
            },
            "triggered": True,
            "trigger_reason": f"Triggered by: {event}",
        }

    return {"lesson": None, "triggered": False, "trigger_reason": ""}


def _evaluate_conditions(conditions: dict, context: dict) -> bool:
    """Simple rule evaluator for trigger conditions."""
    for key, rule in conditions.items():
        value = context.get(key)
        if value is None:
            return False
        if isinstance(rule, dict):
            if "gte" in rule and value < rule["gte"]:
                return False
            if "lte" in rule and value > rule["lte"]:
                return False
            if "eq" in rule and value != rule["eq"]:
                return False
            if "in" in rule and value not in rule["in"]:
                return False
        elif value != rule:
            return False
    return True


async def complete_lesson(db: AsyncSession, user_id: uuid.UUID, lesson_id: uuid.UUID) -> dict:
    """Mark a lesson as completed and award XP."""
    lesson_result = await db.execute(select(MicroLesson).where(MicroLesson.id == lesson_id))
    lesson = lesson_result.scalar_one_or_none()
    if not lesson:
        return {"xp_awarded": 0, "message": "Lesson not found"}

    # Find the most recent history entry
    history_result = await db.execute(
        select(UserLessonHistory)
        .where(
            and_(
                UserLessonHistory.user_id == user_id,
                UserLessonHistory.lesson_id == lesson_id,
                UserLessonHistory.completed == False,
            )
        )
        .order_by(UserLessonHistory.shown_at.desc())
        .limit(1)
    )
    history = history_result.scalar_one_or_none()

    xp_awarded = 0
    if history and not history.xp_awarded:
        history.completed = True
        history.xp_awarded = True
        xp_result = await award_xp(
            db, user_id, "lesson_completed", source_id=str(lesson_id), override_xp=lesson.xp_reward
        )
        xp_awarded = xp_result["xp_awarded"]

    await db.flush()
    return {"xp_awarded": xp_awarded, "message": f"Урок «{lesson.title}» завершён! +{xp_awarded} XP"}


async def get_lesson_history(db: AsyncSession, user_id: uuid.UUID, limit: int = 20) -> list[dict]:
    """Get user's lesson history."""
    result = await db.execute(
        select(UserLessonHistory, MicroLesson)
        .join(MicroLesson, UserLessonHistory.lesson_id == MicroLesson.id)
        .where(UserLessonHistory.user_id == user_id)
        .order_by(UserLessonHistory.shown_at.desc())
        .limit(limit)
    )

    return [
        {
            "id": str(h.id),
            "lesson_id": str(h.lesson_id),
            "lesson_title": l.title,
            "shown_at": h.shown_at,
            "completed": h.completed,
            "xp_awarded": h.xp_awarded,
        }
        for h, l in result.all()
    ]
