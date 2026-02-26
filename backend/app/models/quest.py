import uuid
from datetime import UTC, datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class QuestTemplate(Base):
    __tablename__ = "quest_templates"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    slug: Mapped[str] = mapped_column(String(80), unique=True, nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(String(50), nullable=False, default="general")
    difficulty: Mapped[str] = mapped_column(String(20), nullable=False, default="easy")
    xp_reward: Mapped[int] = mapped_column(Integer, nullable=False, default=50)
    target_value: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    action_type: Mapped[str] = mapped_column(String(50), nullable=False)
    icon_emoji: Mapped[str] = mapped_column(String(10), default="🎯")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_repeatable: Mapped[bool] = mapped_column(Boolean, default=False)
    conditions: Mapped[dict] = mapped_column(JSONB, nullable=False, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))


class UserQuest(Base):
    __tablename__ = "user_quests"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True)
    quest_template_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("quest_templates.id", ondelete="CASCADE"), index=True)
    status: Mapped[str] = mapped_column(String(20), default="active")
    current_value: Mapped[int] = mapped_column(Integer, default=0)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    xp_awarded: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(UTC), onupdate=lambda: datetime.now(UTC))
