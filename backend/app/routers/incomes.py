import uuid
from datetime import datetime

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import CurrentUser, DbSession
from app.models.income import Income
from app.schemas.income import IncomeCreate, IncomeRead, IncomeUpdate

router = APIRouter(prefix="/incomes", tags=["Incomes"])


@router.post("/", response_model=IncomeRead, status_code=status.HTTP_201_CREATED)
async def create_income(data: IncomeCreate, user: CurrentUser, db: DbSession):
    income = Income(user_id=user.id, **data.model_dump())
    db.add(income)
    await db.flush()
    return income


@router.get("/", response_model=list[IncomeRead])
async def list_incomes(
    user: CurrentUser,
    db: DbSession,
    source_type: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=100),
):
    query = select(Income).where(Income.user_id == user.id)
    if source_type:
        query = query.where(Income.source_type == source_type)
    if date_from:
        query = query.where(Income.received_at >= date_from)
    if date_to:
        query = query.where(Income.received_at <= date_to)
    query = query.order_by(Income.received_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{income_id}", response_model=IncomeRead)
async def get_income(income_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(Income).where(and_(Income.id == income_id, Income.user_id == user.id))
    )
    income = result.scalar_one_or_none()
    if not income:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Income not found")
    return income


@router.patch("/{income_id}", response_model=IncomeRead)
async def update_income(income_id: uuid.UUID, data: IncomeUpdate, user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(Income).where(and_(Income.id == income_id, Income.user_id == user.id))
    )
    income = result.scalar_one_or_none()
    if not income:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Income not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(income, field, value)
    await db.flush()
    return income


@router.delete("/{income_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_income(income_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(Income).where(and_(Income.id == income_id, Income.user_id == user.id))
    )
    income = result.scalar_one_or_none()
    if not income:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Income not found")
    await db.delete(income)
