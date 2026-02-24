import uuid
from datetime import UTC, date, datetime, timedelta
from decimal import Decimal

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.expense import Expense
from app.models.goal import Goal
from app.models.goal_contribution import GoalContribution
from app.models.income import Income
from app.models.report import WeeklyReport


async def generate_weekly_report(db: AsyncSession, user_id: uuid.UUID) -> WeeklyReport:
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)

    start_dt = datetime.combine(week_start, datetime.min.time()).replace(tzinfo=UTC)
    end_dt = datetime.combine(week_end, datetime.max.time()).replace(tzinfo=UTC)

    income_result = await db.execute(
        select(func.coalesce(func.sum(Income.amount), 0)).where(
            and_(Income.user_id == user_id, Income.received_at >= start_dt, Income.received_at <= end_dt)
        )
    )
    total_income = float(income_result.scalar())

    expense_result = await db.execute(
        select(func.coalesce(func.sum(Expense.amount), 0)).where(
            and_(Expense.user_id == user_id, Expense.spent_at >= start_dt, Expense.spent_at <= end_dt)
        )
    )
    total_expenses = float(expense_result.scalar())

    category_result = await db.execute(
        select(Expense.category, func.sum(Expense.amount).label("total")).where(
            and_(Expense.user_id == user_id, Expense.spent_at >= start_dt, Expense.spent_at <= end_dt)
        ).group_by(Expense.category).order_by(func.sum(Expense.amount).desc())
    )
    top_categories = [{"category": row.category, "total": float(row.total)} for row in category_result.all()]

    contribution_result = await db.execute(
        select(func.coalesce(func.sum(GoalContribution.amount), 0)).where(
            and_(GoalContribution.user_id == user_id, GoalContribution.contributed_at >= start_dt, GoalContribution.contributed_at <= end_dt)
        )
    )
    total_contributions = float(contribution_result.scalar())

    goals_result = await db.execute(select(Goal).where(and_(Goal.user_id == user_id, Goal.status == "active")))
    goals = goals_result.scalars().all()
    goals_progress = []
    for g in goals:
        pct = float(g.current_amount / g.target_amount * 100) if g.target_amount > 0 else 0
        goals_progress.append({"title": g.title, "percent": round(pct, 1), "remaining": float(g.target_amount - g.current_amount)})

    savings_rate = round((total_income - total_expenses) / total_income * 100, 1) if total_income > 0 else 0

    summary_json = {
        "total_income": total_income,
        "total_expenses": total_expenses,
        "net": total_income - total_expenses,
        "savings_rate": savings_rate,
        "top_categories": top_categories[:5],
        "total_goal_contributions": total_contributions,
        "goals_progress": goals_progress,
    }

    lines = [f"📊 Your week at a glance ({week_start.strftime('%b %d')} — {week_end.strftime('%b %d')})"]
    lines.append(f"You earned {total_income:,.0f} and spent {total_expenses:,.0f}.")

    if total_income > total_expenses:
        lines.append(f"Great job! You saved {total_income - total_expenses:,.0f} ({savings_rate}% savings rate).")
    elif total_income == total_expenses:
        lines.append("You broke even this week. Let's see if we can save a little next week!")
    else:
        lines.append(f"You overspent by {total_expenses - total_income:,.0f}. No worries — let's plan better for next week.")

    if top_categories:
        top = top_categories[0]
        lines.append(f"Your biggest spending category was {top['category']} ({top['total']:,.0f}).")

    if total_contributions > 0:
        lines.append(f"You contributed {total_contributions:,.0f} to your goals this week. Keep it up! 🎯")

    for gp in goals_progress:
        lines.append(f"• {gp['title']}: {gp['percent']}% done, {gp['remaining']:,.0f} to go")

    lines.append("Remember: every small step counts. You're doing great! 💪")

    summary_text = "\n".join(lines)

    report = WeeklyReport(
        user_id=user_id,
        week_start=week_start,
        week_end=week_end,
        summary_json=summary_json,
        summary_text=summary_text,
    )
    db.add(report)
    await db.flush()
    return report
