from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.logging import logger
from app.routers import auth, profile, incomes, expenses, goals, budgets, simulator, anti_impulse, reports, ai_coach, analytics


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Zense API starting up")
    yield
    logger.info("Zense API shutting down")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Zense — Gen Z financial coaching & budgeting API. Educational & budgeting guidance only, not financial advice.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

prefix = settings.API_PREFIX

app.include_router(auth.router, prefix=prefix)
app.include_router(profile.router, prefix=prefix)
app.include_router(incomes.router, prefix=prefix)
app.include_router(expenses.router, prefix=prefix)
app.include_router(goals.router, prefix=prefix)
app.include_router(budgets.router, prefix=prefix)
app.include_router(simulator.router, prefix=prefix)
app.include_router(anti_impulse.router, prefix=prefix)
app.include_router(reports.router, prefix=prefix)
app.include_router(ai_coach.router, prefix=prefix)
app.include_router(analytics.router, prefix=prefix)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"Unhandled error: {exc}", exc_info=True)
    return JSONResponse(status_code=500, content={"success": False, "message": "Internal server error"})


@app.get("/health")
async def health():
    return {"status": "ok", "version": settings.APP_VERSION}
