"""
Quest Service — manages quest lifecycle: assignment, progress, completion.
"""

import uuid
from datetime import UTC, datetime

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.quest import QuestTemplate, UserQuest
from app.services.xp_service import award_xp


async def get_available_quests(db: AsyncSession, user_id: uuid.UUID) -> list[QuestTemplate]:
    """Get quest templates not yet started by user (or repeatable ones)."""
    # Get IDs of quests user already has active/completed
    user_quest_ids = (
        select(UserQuest.quest_template_id)
        .where(and_(UserQuest.user_id == user_id, UserQuest.status.in_(["active", "completed"])))
    )

    result = await db.execute(
        select(QuestTemplate).where(
            and_(
                QuestTemplate.is_active == True,
                ~QuestTemplate.id.in_(user_quest_ids) | (QuestTemplate.is_repeatable == True),
            )
        )
    )
    return list(result.scalars().all())


async def get_user_quests(db: AsyncSession, user_id: uuid.UUID) -> dict:
    """Get all user quests grouped by status."""
    result = await db.execute(
        select(UserQuest, QuestTemplate)
        .join(QuestTemplate, UserQuest.quest_template_id == QuestTemplate.id)
        .where(UserQuest.user_id == user_id)
        .order_by(UserQuest.created_at.desc())
    )
    rows = result.all()

    active = []
    completed = []

    for uq, qt in rows:
        quest_data = {
            "id": str(uq.id),
            "quest_template_id": str(qt.id),
            "status": uq.status,
            "current_value": uq.current_value,
            "target_value": qt.target_value,
            "title": qt.title,
            "description": qt.description,
            "xp_reward": qt.xp_reward,
            "icon_emoji": qt.icon_emoji,
            "difficulty": qt.difficulty,
            "progress_percent": round(min(uq.current_value / max(qt.target_value, 1), 1.0) * 100, 1),
            "started_at": uq.started_at,
            "completed_at": uq.completed_at,
        }
        if uq.status == "completed":
            completed.append(quest_data)
        else:
            active.append(quest_data)

    # Available quests
    available_templates = await get_available_quests(db, user_id)
    available = [
        {
            "id": str(qt.id),
            "slug": qt.slug,
            "title": qt.title,
            "description": qt.description,
            "category": qt.category,
            "difficulty": qt.difficulty,
            "xp_reward": qt.xp_reward,
            "target_value": qt.target_value,
            "action_type": qt.action_type,
            "icon_emoji": qt.icon_emoji,
            "is_repeatable": qt.is_repeatable,
        }
        for qt in available_templates
    ]

    return {"active": active, "completed": completed, "available": available}


async def start_quest(db: AsyncSession, user_id: uuid.UUID, quest_template_id: uuid.UUID) -> dict:
    """Start a quest for a user."""
    template_result = await db.execute(select(QuestTemplate).where(QuestTemplate.id == quest_template_id))
    template = template_result.scalar_one_or_none()
    if not template:
        raise ValueError("Quest template not found")

    # Check if already active
    existing = await db.execute(
        select(UserQuest).where(
            and_(
                UserQuest.user_id == user_id,
                UserQuest.quest_template_id == quest_template_id,
                UserQuest.status == "active",
            )
        )
    )
    if existing.scalar_one_or_none():
        raise ValueError("Quest already active")

    user_quest = UserQuest(
        user_id=user_id,
        quest_template_id=quest_template_id,
        status="active",
        current_value=0,
    )
    db.add(user_quest)
    await db.flush()

    return {
        "id": str(user_quest.id),
        "quest_template_id": str(template.id),
        "status": "active",
        "current_value": 0,
        "target_value": template.target_value,
        "title": template.title,
        "description": template.description,
        "xp_reward": template.xp_reward,
        "icon_emoji": template.icon_emoji,
        "difficulty": template.difficulty,
        "progress_percent": 0.0,
        "started_at": user_quest.started_at,
        "completed_at": None,
    }


async def update_quest_progress(
    db: AsyncSession, user_id: uuid.UUID, action_type: str, increment: int = 1
) -> list[dict]:
    """Called after a financial action; increments matching active quests."""
    result = await db.execute(
        select(UserQuest, QuestTemplate)
        .join(QuestTemplate, UserQuest.quest_template_id == QuestTemplate.id)
        .where(
            and_(
                UserQuest.user_id == user_id,
                UserQuest.status == "active",
                QuestTemplate.action_type == action_type,
            )
        )
    )

    completed_quests = []
    for uq, qt in result.all():
        uq.current_value = min(uq.current_value + increment, qt.target_value)

        if uq.current_value >= qt.target_value:
            uq.status = "completed"
            uq.completed_at = datetime.now(UTC)
            if not uq.xp_awarded:
                await award_xp(db, user_id, "quest_completed", source_id=str(qt.id), override_xp=qt.xp_reward)
                uq.xp_awarded = True
            completed_quests.append({
                "quest_title": qt.title,
                "xp_reward": qt.xp_reward,
                "icon_emoji": qt.icon_emoji,
            })

    await db.flush()
    return completed_quests
