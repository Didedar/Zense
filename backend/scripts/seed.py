import asyncio
import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import async_session_factory, engine, Base
from app.core.security import hash_password
from app.models.user import User
from app.models.profile import UserProfile
from app.models.income import Income
from app.models.expense import Expense
from app.models.goal_contribution import GoalContribution
from app.models.budget import BudgetPlan
from app.models.report import WeeklyReport


DEMO_EMAIL = "demo@zense.kz"
DEMO_PASSWORD = "demo1234"


async def seed():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session_factory() as db:
        existing = await db.execute(select(User).where(User.email == DEMO_EMAIL))
        if existing.scalar_one_or_none():
            print(f"Demo user {DEMO_EMAIL} already exists, skipping seed.")
            return

        user = User(email=DEMO_EMAIL, password_hash=hash_password(DEMO_PASSWORD))
        db.add(user)
        await db.flush()

        profile = UserProfile(
            user_id=user.id,
            display_name="Demo User",
            age=18,
            segment="student",
            currency="KZT",
            timezone="Asia/Almaty",
            onboarding_completed=True,
            spending_style="medium",
        )
        db.add(profile)

        now = datetime.now(UTC)

        incomes_data = [
            {"amount": Decimal("80000"), "source_type": "scholarship", "received_at": now - timedelta(days=20), "note": "University scholarship", "is_recurring": True, "recurring_period": "monthly"},
            {"amount": Decimal("35000"), "source_type": "freelance", "received_at": now - timedelta(days=10), "note": "Logo design project"},
            {"amount": Decimal("25000"), "source_type": "family", "received_at": now - timedelta(days=5), "note": "From parents"},
        ]
        for inc in incomes_data:
            db.add(Income(user_id=user.id, **inc))

        expenses_data = [
            {"amount": Decimal("3500"), "category": "food", "spent_at": now - timedelta(days=14), "merchant_name": "Magnum"},
            {"amount": Decimal("2800"), "category": "food", "spent_at": now - timedelta(days=12), "merchant_name": "Glovo"},
            {"amount": Decimal("1500"), "category": "transport", "spent_at": now - timedelta(days=11), "note": "Bus card top-up"},
            {"amount": Decimal("5990"), "category": "subscriptions", "spent_at": now - timedelta(days=10), "merchant_name": "Spotify + iCloud"},
            {"amount": Decimal("12000"), "category": "shopping", "spent_at": now - timedelta(days=9), "merchant_name": "Zara", "is_impulse_flag": True},
            {"amount": Decimal("4200"), "category": "food", "spent_at": now - timedelta(days=8), "merchant_name": "Wolt"},
            {"amount": Decimal("2000"), "category": "entertainment", "spent_at": now - timedelta(days=7), "note": "Cinema"},
            {"amount": Decimal("1800"), "category": "transport", "spent_at": now - timedelta(days=6), "note": "Yandex taxi"},
            {"amount": Decimal("6500"), "category": "education", "spent_at": now - timedelta(days=5), "merchant_name": "Udemy course"},
            {"amount": Decimal("3200"), "category": "food", "spent_at": now - timedelta(days=4), "merchant_name": "KFC"},
            {"amount": Decimal("8000"), "category": "shopping", "spent_at": now - timedelta(days=3), "merchant_name": "Kaspi Магазин"},
            {"amount": Decimal("1500"), "category": "health", "spent_at": now - timedelta(days=2), "note": "Pharmacy"},
            {"amount": Decimal("4500"), "category": "food", "spent_at": now - timedelta(days=1), "merchant_name": "Starbucks + lunch"},
            {"amount": Decimal("2500"), "category": "entertainment", "spent_at": now - timedelta(hours=6), "note": "Bowling"},
            {"amount": Decimal("1000"), "category": "other", "spent_at": now - timedelta(hours=2), "note": "Phone case"},
        ]
        for exp in expenses_data:
            db.add(Expense(user_id=user.id, **exp))

        goal1 = Goal(
            user_id=user.id,
            title="iPhone 16",
            target_amount=Decimal("450000"),
            current_amount=Decimal("120000"),
            target_date=date.today() + timedelta(days=90),
            priority=1,
            status="active",
            category="gadget",
        )
        goal2 = Goal(
            user_id=user.id,
            title="Trip to Tbilisi",
            target_amount=Decimal("200000"),
            current_amount=Decimal("45000"),
            target_date=date.today() + timedelta(days=180),
            priority=2,
            status="active",
            category="travel",
        )
        db.add(goal1)
        db.add(goal2)
        await db.flush()

        db.add(GoalContribution(user_id=user.id, goal_id=goal1.id, amount=Decimal("20000"), contributed_at=now - timedelta(days=7), source="manual"))
        db.add(GoalContribution(user_id=user.id, goal_id=goal2.id, amount=Decimal("10000"), contributed_at=now - timedelta(days=7), source="manual"))

        today = date.today()
        week_start = today - timedelta(days=today.weekday())
        week_end = week_start + timedelta(days=6)

        plan = BudgetPlan(
            user_id=user.id,
            period_type="weekly",
            period_start=week_start,
            period_end=week_end,
            total_income_planned=Decimal("35000"),
            flexible_planned=Decimal("21000"),
            goal_contribution_planned=Decimal("8750"),
            reserve_planned=Decimal("5250"),
            is_active=True,
        )
        db.add(plan)
        await db.flush()

        report = WeeklyReport(
            user_id=user.id,
            week_start=week_start - timedelta(days=7),
            week_end=week_start - timedelta(days=1),
            summary_json={
                "total_income": 140000,
                "total_expenses": 58990,
                "net": 81010,
                "savings_rate": 57.9,
                "top_categories": [{"category": "shopping", "total": 20000}, {"category": "food", "total": 18200}],
                "total_goal_contributions": 30000,
                "goals_progress": [
                    {"title": "iPhone 16", "percent": 26.7, "remaining": 330000},
                    {"title": "Trip to Tbilisi", "percent": 22.5, "remaining": 155000},
                ],
            },
            summary_text=(
                "📊 Your week at a glance\n"
                "You earned 140,000 and spent 58,990.\n"
                "Great job! You saved 81,010 (57.9% savings rate).\n"
                "Your biggest spending category was shopping (20,000).\n"
                "You contributed 30,000 to your goals this week. Keep it up! 🎯\n"
                "• iPhone 16: 26.7% done, 330,000 to go\n"
                "• Trip to Tbilisi: 22.5% done, 155,000 to go\n"
                "Remember: every small step counts. You're doing great! 💪"
            ),
        )
        db.add(report)

        await db.commit()
        print(f"Seeded demo user: {DEMO_EMAIL} / {DEMO_PASSWORD}")
        print("Seeded: 3 incomes, 15 expenses, 2 goals, 1 budget plan, 1 weekly report")


if __name__ == "__main__":
    asyncio.run(seed())
