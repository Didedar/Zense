# Zense — Gen Z Financial Coaching Backend

Fintech MVP backend for Gen Z (16–20) — budgeting, goals, smart spending decisions, and AI coaching.

> **Disclaimer**: This is educational & budgeting guidance, not financial advice. No banking integrations, no KYC, no payments.

## Stack

- **Python 3.12+** / **FastAPI** / **Pydantic v2**
- **PostgreSQL 16** + **SQLAlchemy 2.x** (async) + **Alembic**
- **JWT auth** (access + refresh tokens)
- **Redis** (optional, for future caching/rate limits)
- **Docker** + **docker-compose**

## Quick Start

### 1. Docker (recommended)

```bash
cp .env.example .env
docker-compose up --build
```

API available at `http://localhost:8000`
Swagger docs at `http://localhost:8000/docs`

### 2. Local Development

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -r requirements-dev.txt

cp .env.example .env
# Edit .env with your DATABASE_URL

# Run migrations
alembic upgrade head

# Seed demo data
python -m scripts.seed

# Start server
uvicorn app.main:app --reload
```

### 3. Run Tests

```bash
pytest tests/ -v
```

## Demo Credentials

- **Email**: `demo@zense.kz`
- **Password**: `demo1234`

## API Overview

All endpoints under `/api/v1/`. Full docs at `/docs`.

| Module | Endpoints |
|---|---|
| Auth | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me` |
| Profile | `GET /profile`, `PATCH /profile`, `POST /onboarding/complete` |
| Incomes | CRUD at `/incomes` + filters |
| Expenses | CRUD at `/expenses` + filters |
| Goals | CRUD at `/goals` + `POST /goals/{id}/contribute` + `GET /goals/{id}/progress` |
| Budgets | `POST /budgets/plan/generate`, `GET /budgets/current`, `GET /budgets/safe-to-spend/today`, `GET /budgets/health-check` |
| Simulator | `POST /simulator/purchase-impact` |
| Anti-Impulse | `POST /anti-impulse/start`, `POST /anti-impulse/{id}/resolve`, `GET /anti-impulse/history` |
| Reports | `POST /reports/weekly/generate`, `GET /reports/weekly/latest` |
| AI Coach | `POST /ai/coach/ask`, `GET /ai/coach/insights/latest` |
| Analytics | `POST /events/track`, `GET /analytics/dashboard/summary` |

## Key Features

- **Safe-to-Spend Today** — daily spending limit based on budget plan
- **Purchase Impact Simulator** — "what happens if I buy X?" with goal ETA shifts
- **Anti-Impulse Protection** — risk scoring (0-100) with cooldown timers
- **AI Coach** — rule-based + Gemini LLM stub for financial guidance
- **Weekly Reports** — human-readable summaries with zero-shame tone

## Project Structure

```
app/
├── core/           # config, database, security, deps, logging
├── models/         # SQLAlchemy models (12 tables)
├── schemas/        # Pydantic v2 request/response schemas
├── services/       # Business logic (budget, simulator, coach, anti-impulse, reports)
├── routers/        # FastAPI route handlers (11 modules)
└── main.py         # App entrypoint

scripts/seed.py     # Demo data seeder
tests/              # Pytest test suite
alembic/            # Database migrations
```

## Environment Variables

See `.env.example` for all configuration options. Key ones:

- `DATABASE_URL` — PostgreSQL connection string
- `JWT_SECRET_KEY` — Change in production!
- `GEMINI_API_KEY` — Optional, for LLM-powered AI coach
