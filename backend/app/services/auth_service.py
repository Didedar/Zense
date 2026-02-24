import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, create_refresh_token, decode_token, hash_password, verify_password
from app.models.profile import UserProfile
from app.models.user import User


async def register_user(db: AsyncSession, email: str, password: str, display_name: str) -> User:
    result = await db.execute(select(User).where(User.email == email))
    if result.scalar_one_or_none():
        raise ValueError("Email already registered")

    user = User(email=email, password_hash=hash_password(password))
    db.add(user)
    await db.flush()

    profile = UserProfile(user_id=user.id, display_name=display_name)
    db.add(profile)
    await db.flush()

    return user


async def authenticate_user(db: AsyncSession, email: str, password: str) -> User:
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(password, user.password_hash):
        raise ValueError("Invalid email or password")
    if not user.is_active:
        raise ValueError("Account is inactive")
    return user


def generate_tokens(user_id: uuid.UUID) -> dict:
    return {
        "access_token": create_access_token(str(user_id)),
        "refresh_token": create_refresh_token(str(user_id)),
        "token_type": "bearer",
    }


async def refresh_access_token(db: AsyncSession, refresh_token: str) -> dict:
    payload = decode_token(refresh_token)
    if payload.get("type") != "refresh":
        raise ValueError("Invalid token type")

    user_id = payload.get("sub")
    result = await db.execute(select(User).where(User.id == uuid.UUID(user_id)))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise ValueError("User not found or inactive")

    return generate_tokens(user.id)
