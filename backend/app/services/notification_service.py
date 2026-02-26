"""
Notification Service — in-app notifications (MVP-friendly, polling-based).
"""

import uuid

from sqlalchemy import and_, false, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.notification import Notification


async def create_notification(
    db: AsyncSession,
    user_id: uuid.UUID,
    title: str,
    body: str,
    notification_type: str,
    action_url: str | None = None,
    payload: dict | None = None,
) -> Notification:
    """Create an in-app notification."""
    notif = Notification(
        user_id=user_id,
        title=title,
        body=body,
        notification_type=notification_type,
        action_url=action_url,
        payload=payload or {},
    )
    db.add(notif)
    await db.flush()
    return notif


async def get_notifications(
    db: AsyncSession,
    user_id: uuid.UUID,
    unread_only: bool = False,
    limit: int = 50,
) -> dict:
    """Get user's notifications."""
    query = select(Notification).where(Notification.user_id == user_id)
    if unread_only:
        query = query.where(Notification.is_read == False)
    query = query.order_by(Notification.created_at.desc()).limit(limit)

    result = await db.execute(query)
    notifications = result.scalars().all()

    # Unread count
    count_result = await db.execute(
        select(func.count()).where(
            and_(Notification.user_id == user_id, Notification.is_read == False)
        )
    )
    unread_count = count_result.scalar()

    return {
        "notifications": [
            {
                "id": str(n.id),
                "title": n.title,
                "body": n.body,
                "notification_type": n.notification_type,
                "action_url": n.action_url,
                "payload": n.payload,
                "is_read": n.is_read,
                "created_at": n.created_at,
            }
            for n in notifications
        ],
        "unread_count": unread_count or 0,
    }


async def mark_as_read(db: AsyncSession, user_id: uuid.UUID, notification_ids: list[str]) -> int:
    """Mark notifications as read."""
    uuids = [uuid.UUID(nid) for nid in notification_ids]
    result = await db.execute(
        update(Notification)
        .where(and_(Notification.user_id == user_id, Notification.id.in_(uuids)))
        .values(is_read=True)
    )
    await db.flush()
    return result.rowcount


async def mark_all_read(db: AsyncSession, user_id: uuid.UUID) -> int:
    """Mark all notifications as read."""
    result = await db.execute(
        update(Notification)
        .where(and_(Notification.user_id == user_id, Notification.is_read == False))
        .values(is_read=True)
    )
    await db.flush()
    return result.rowcount


async def get_unread_count(db: AsyncSession, user_id: uuid.UUID) -> int:
    """Get just the unread count for badge display."""
    result = await db.execute(
        select(func.count()).where(
            and_(Notification.user_id == user_id, Notification.is_read == False)
        )
    )
    return result.scalar() or 0


# ── Notification Rules — fire notifications based on events ──

NOTIFICATION_RULES = {
    "budget_warning": {
        "title": "⚠️ Бюджет под давлением",
        "body": "Вы потратили более 80% развлекательного бюджета. Будьте внимательнее!",
        "type": "warning",
        "action_url": "/budgets",
    },
    "budget_exceeded": {
        "title": "🚨 Бюджет превышен",
        "body": "Развлекательный бюджет исчерпан. Постарайтесь воздержаться от необязательных трат.",
        "type": "alert",
        "action_url": "/budgets",
    },
    "streak_milestone": {
        "title": "🔥 Серия дней!",
        "body": "Вы уже {streak_days} дней подряд используете Zense! Продолжайте!",
        "type": "achievement",
        "action_url": "/profile",
    },
    "level_up": {
        "title": "🎉 Новый уровень!",
        "body": "Поздравляем! Вы достигли уровня {level}!",
        "type": "achievement",
        "action_url": "/profile",
    },
    "quest_completed": {
        "title": "✅ Квест выполнен!",
        "body": "Вы выполнили квест «{quest_title}» и получили {xp_reward} XP!",
        "type": "achievement",
        "action_url": "/quests",
    },
    "goal_progress": {
        "title": "🎯 Прогресс по цели",
        "body": "Ваша цель «{goal_title}» достигла {percent}%! Так держать!",
        "type": "info",
        "action_url": "/goals",
    },
    "weekly_report_ready": {
        "title": "📊 Недельный отчёт готов",
        "body": "Ваш еженедельный финансовый отчёт готов к просмотру.",
        "type": "info",
        "action_url": "/reports",
    },
    "impulse_saved": {
        "title": "💪 Вы сэкономили!",
        "body": "Отличное решение! Вы сэкономили {amount} ₸, устояв перед импульсивной покупкой.",
        "type": "achievement",
        "action_url": "/anti-impulse",
    },
}


async def fire_notification_rule(
    db: AsyncSession, user_id: uuid.UUID, rule_key: str, context: dict | None = None
) -> Notification | None:
    """Create a notification from a predefined rule."""
    rule = NOTIFICATION_RULES.get(rule_key)
    if not rule:
        return None

    body = rule["body"]
    title = rule["title"]
    if context:
        try:
            body = body.format(**context)
            title = title.format(**context)
        except KeyError:
            pass

    return await create_notification(
        db=db,
        user_id=user_id,
        title=title,
        body=body,
        notification_type=rule["type"],
        action_url=rule.get("action_url"),
        payload=context or {},
    )
