from fastapi import APIRouter, Query
from sqlalchemy import select

from app.core.deps import CurrentUser, DbSession
from app.models.report import WeeklyReport
from app.schemas.report import WeeklyReportRead
from app.services.report_service import generate_weekly_report

router = APIRouter(prefix="/reports", tags=["Reports"])


@router.post("/weekly/generate", response_model=WeeklyReportRead, status_code=201)
async def generate(user: CurrentUser, db: DbSession):
    return await generate_weekly_report(db, user.id)


@router.get("/weekly/latest", response_model=WeeklyReportRead | None)
async def latest(user: CurrentUser, db: DbSession):
    result = await db.execute(
        select(WeeklyReport)
        .where(WeeklyReport.user_id == user.id)
        .order_by(WeeklyReport.created_at.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()


@router.get("/weekly", response_model=list[WeeklyReportRead])
async def list_reports(
    user: CurrentUser,
    db: DbSession,
    limit: int = Query(default=10, ge=1, le=50),
):
    result = await db.execute(
        select(WeeklyReport)
        .where(WeeklyReport.user_id == user.id)
        .order_by(WeeklyReport.created_at.desc())
        .limit(limit)
    )
    return result.scalars().all()
