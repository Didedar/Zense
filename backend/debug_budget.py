import asyncio
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__))))

from sqlalchemy import select
from app.core.database import async_session_factory
from app.models.user import User
from app.models.budget import BudgetPlan
from app.models.expense import Expense
from app.services.budget_service import get_safe_to_spend
from datetime import UTC

async def debug():
    async with async_session_factory() as db:
        users_res = await db.execute(select(User))
        users = users_res.scalars().all()
        for user in users:
            print(f"\nUser: {user.email}")
            plan_res = await db.execute(select(BudgetPlan).where(BudgetPlan.user_id == user.id, BudgetPlan.is_active == True))
            plan = plan_res.scalars().first()
            if plan:
                print(f"Active Plan: start={plan.period_start}, end={plan.period_end}")
            else:
                print("No active plan found")
                
            exps_res = await db.execute(select(Expense).where(Expense.user_id == user.id))
            exps = exps_res.scalars().all()
            for e in exps:
                print(f"Expense: ID={e.id} amount={e.amount} category={e.category} spent_at={e.spent_at} (UTC: {e.spent_at.astimezone(UTC) if e.spent_at.tzinfo else 'NA'}) fixed={e.is_fixed} kind={e.expense_kind}")
                
            res = await get_safe_to_spend(db, user.id)
            print(f"variable_spent={res.get('variable_spent')}, fixed_spent={res.get('fixed_spent')}")
            print(f"safe_to_spend_today={res.get('safe_to_spend_today')}, spending_limit={res.get('spending_limit')}, remaining={res.get('remaining_free')}")

if __name__ == "__main__":
    asyncio.run(debug())
