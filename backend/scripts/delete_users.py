import asyncio
import sys
import os

# Add backend dir to pythonpath if not already
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from sqlalchemy import delete
from app.core.database import async_session_factory
from app.models.user import User

async def delete_all():
    async with async_session_factory() as db:
        result = await db.execute(delete(User))
        await db.commit()
        print("All users and their related data have been successfully deleted.")

if __name__ == "__main__":
    asyncio.run(delete_all())
