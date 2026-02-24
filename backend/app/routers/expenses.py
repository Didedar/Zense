import uuid
from datetime import datetime

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import and_, select

from app.core.deps import CurrentUser, DbSession
from app.models.expense import Expense
from app.schemas.expense import ExpenseCreate, ExpenseRead, ExpenseUpdate

router = APIRouter(prefix="/expenses", tags=["Expenses"])


@router.post("/", response_model=ExpenseRead, status_code=status.HTTP_201_CREATED)
async def create_expense(data: ExpenseCreate, user: CurrentUser, db: DbSession):
    expense = Expense(user_id=user.id, **data.model_dump())
    db.add(expense)
    await db.flush()
    return expense


@router.get("/", response_model=list[ExpenseRead])
async def list_expenses(
    user: CurrentUser,
    db: DbSession,
    category: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=100),
):
    query = select(Expense).where(Expense.user_id == user.id)
    if category:
        query = query.where(Expense.category == category)
    if date_from:
        query = query.where(Expense.spent_at >= date_from)
    if date_to:
        query = query.where(Expense.spent_at <= date_to)
    query = query.order_by(Expense.spent_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{expense_id}", response_model=ExpenseRead)
async def get_expense(expense_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(Expense).where(and_(Expense.id == expense_id, Expense.user_id == user.id))
    )
    expense = result.scalar_one_or_none()
    if not expense:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    return expense


@router.patch("/{expense_id}", response_model=ExpenseRead)
async def update_expense(expense_id: uuid.UUID, data: ExpenseUpdate, user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(Expense).where(and_(Expense.id == expense_id, Expense.user_id == user.id))
    )
    expense = result.scalar_one_or_none()
    if not expense:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(expense, field, value)
    await db.flush()
    return expense


@router.delete("/{expense_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_expense(expense_id: uuid.UUID, user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(Expense).where(and_(Expense.id == expense_id, Expense.user_id == user.id))
    )
    expense = result.scalar_one_or_none()
    if not expense:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Expense not found")
    await db.delete(expense)
