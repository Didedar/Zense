from datetime import UTC, datetime

import pytest
from httpx import AsyncClient


async def _setup_budget(client: AsyncClient):
    await client.post("/api/v1/incomes", json={
        "amount": "100000",
        "source_type": "scholarship",
        "received_at": datetime.now(UTC).isoformat(),
    })
    resp = await client.post("/api/v1/budgets/plan/generate", json={"period_type": "weekly"})
    return resp


@pytest.mark.asyncio
async def test_generate_budget(auth_client: AsyncClient):
    resp = await _setup_budget(auth_client)
    assert resp.status_code == 201
    data = resp.json()
    assert data["is_active"] is True
    assert float(data["total_income_planned"]) > 0


@pytest.mark.asyncio
async def test_safe_to_spend(auth_client: AsyncClient):
    await _setup_budget(auth_client)
    resp = await auth_client.get("/api/v1/budgets/safe-to-spend/today")
    assert resp.status_code == 200
    data = resp.json()
    assert "safe_to_spend_today" in data
    assert data["status"] in ("good", "warning", "risk")
    assert isinstance(data["warnings"], list)


@pytest.mark.asyncio
async def test_safe_to_spend_no_plan(auth_client: AsyncClient):
    resp = await auth_client.get("/api/v1/budgets/safe-to-spend/today")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "risk"


@pytest.mark.asyncio
async def test_budget_health(auth_client: AsyncClient):
    await _setup_budget(auth_client)
    resp = await auth_client.get("/api/v1/budgets/health-check")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] in ("good", "warning", "risk")
    assert "score" in data


@pytest.mark.asyncio
async def test_purchase_impact(auth_client: AsyncClient):
    await _setup_budget(auth_client)
    await auth_client.post("/api/v1/goals", json={
        "title": "Test Goal",
        "target_amount": "100000",
        "priority": 1,
    })
    resp = await auth_client.post("/api/v1/simulator/purchase-impact", json={
        "purchase_amount": "5000",
        "category": "shopping",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert "is_safe_now" in data
    assert "recommendation" in data
    assert data["recommendation"] in ("buy_now", "postpone", "reduce", "split")
    assert "reasoning" in data


@pytest.mark.asyncio
async def test_purchase_impact_large(auth_client: AsyncClient):
    await _setup_budget(auth_client)
    resp = await auth_client.post("/api/v1/simulator/purchase-impact", json={
        "purchase_amount": "999999",
        "category": "shopping",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["is_safe_now"] is False


@pytest.mark.asyncio
async def test_weekly_report(auth_client: AsyncClient):
    await auth_client.post("/api/v1/incomes", json={
        "amount": "50000",
        "source_type": "freelance",
        "received_at": datetime.now(UTC).isoformat(),
    })
    await auth_client.post("/api/v1/expenses", json={
        "amount": "10000",
        "category": "food",
        "spent_at": datetime.now(UTC).isoformat(),
    })
    resp = await auth_client.post("/api/v1/reports/weekly/generate")
    assert resp.status_code == 201
    data = resp.json()
    assert "summary_json" in data
    assert "summary_text" in data
    assert data["summary_json"]["total_income"] >= 50000


@pytest.mark.asyncio
async def test_anti_impulse_flow(auth_client: AsyncClient):
    await _setup_budget(auth_client)
    start = await auth_client.post("/api/v1/anti-impulse/start", json={
        "planned_purchase_amount": "15000",
        "category": "shopping",
    })
    assert start.status_code == 201
    data = start.json()
    assert "risk_score" in data
    assert "cooldown_seconds" in data
    session_id = data["session_id"]

    resolve = await auth_client.post(f"/api/v1/anti-impulse/{session_id}/resolve", json={"outcome": "postponed"})
    assert resolve.status_code == 200
    assert resolve.json()["outcome"] == "postponed"


@pytest.mark.asyncio
async def test_ai_coach_ask(auth_client: AsyncClient):
    resp = await auth_client.post("/api/v1/ai/coach/ask", json={"user_message": "I spent too much this week"})
    assert resp.status_code == 200
    data = resp.json()
    assert "answer" in data
    assert data["source"] == "rules"
    assert "disclaimer" in data
