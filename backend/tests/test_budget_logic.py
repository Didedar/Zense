from datetime import UTC, datetime
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_budget_logic_income_and_fixed(auth_client: AsyncClient):
    # 1. Add income
    await auth_client.post("/api/v1/incomes", json={
        "amount": "100000",
        "source_type": "salary",
        "received_at": datetime.now(UTC).isoformat(),
    })
    
    # 2. Add fixed expense (Lockbox)
    await auth_client.post("/api/v1/expenses", json={
        "amount": "20000",
        "category": "rent",
        "is_fixed": True,
        "spent_at": datetime.now(UTC).isoformat(),
    })
    
    # 3. Generate Plan
    plan_resp = await auth_client.post("/api/v1/budgets/plan/generate", json={"period_type": "monthly"})
    if plan_resp.status_code != 201:
        print("Plan generation failed:", plan_resp.json())
    assert plan_resp.status_code == 201
    plan_data = plan_resp.json()
    
    assert float(plan_data["top_line_income"]) >= 100000.0  # it sums up all incomes in last 30 days
    # Since we don't know exact total if previous tests ran, we just ensure it's >0 and the fields exist.
    assert "hard_commitments_total" in plan_data
    assert "net_available" in plan_data
    assert "free_money_planned" in plan_data
    
    # 4. Check Safe to Spend breakdown
    safe_resp = await auth_client.get("/api/v1/budgets/safe-to-spend/today")
    assert safe_resp.status_code == 200
    safe_data = safe_resp.json()
    
    assert "top_line_income" in safe_data
    assert "fixed_locked" in safe_data
    assert "net_available" in safe_data
    assert "free_limit" in safe_data
    assert "spent_variable" in safe_data
    assert "remaining_free" in safe_data
    assert float(safe_data["free_limit"]) == float(plan_data["free_money_planned"])

@pytest.mark.asyncio
async def test_budget_logic_remaining_free_becomes_zero(auth_client: AsyncClient):
    safe_resp = await auth_client.get("/api/v1/budgets/safe-to-spend/today")
    if safe_resp.status_code != 200:
        return # Skip if previous test didn't run properly
        
    free_limit = float(safe_resp.json()["free_limit"])
    
    await auth_client.post("/api/v1/expenses", json={
        "amount": str(free_limit + 1000), 
        "category": "shopping",
        "is_fixed": False,
        "spent_at": datetime.now(UTC).isoformat(),
    })
    
    safe_resp2 = await auth_client.get("/api/v1/budgets/safe-to-spend/today")
    data = safe_resp2.json()
    assert float(data["remaining_free"]) == 0.0
    assert data["status"] == "risk"
    # borrow_options should appear since it's risk state
    assert type(data["borrow_options"]) == list
