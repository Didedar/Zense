import asyncio
from datetime import datetime, UTC
from sqlalchemy import select
from app.core.database import async_session_factory
from app.models.profile import UserProfile
from app.models.user import User
from app.services.budget_service import get_safe_to_spend, generate_budget_plan
from app.models.income import Income
import uuid

async def main():
    async with async_session_factory() as db:
        user_id = None
        result = await db.execute(select(UserProfile))
        for p in result.scalars().all():
            user_id = p.user_id
            break
            
        if not user_id:
            print("No user found.")
            return

        print("--- BEFORE ---")
        safe_data = await get_safe_to_spend(db, user_id)
        print("Safe today:", safe_data.get("safe_to_spend_today"))
        print("Net available:", safe_data.get("net_available"))
        print("Free limit:", safe_data.get("free_limit"))
        print("Top line income:", safe_data.get("top_line_income"))

        print("\n--- ADDING INCOME ---")
        inc = Income(user_id=user_id, amount=10000, source_type="salary", received_at=datetime.now(UTC), note="Test")
        db.add(inc)
        await db.flush()
        
        await generate_budget_plan(db, user_id, "monthly")
        
        print("\n--- AFTER ---")
        safe_data = await get_safe_to_spend(db, user_id)
        print("Safe today:", safe_data.get("safe_to_spend_today"))
        print("Net available:", safe_data.get("net_available"))
        print("Free limit:", safe_data.get("free_limit"))
        print("Top line income:", safe_data.get("top_line_income"))
        
        await db.rollback()

if __name__ == "__main__":
    asyncio.run(main())
