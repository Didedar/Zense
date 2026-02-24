from datetime import UTC, datetime

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_income(auth_client: AsyncClient):
    resp = await auth_client.post("/api/v1/incomes/", json={
        "amount": "50000",
        "source_type": "scholarship",
        "received_at": datetime.now(UTC).isoformat(),
    })
    assert resp.status_code == 201
    data = resp.json()
    assert float(data["amount"]) == 50000
    assert data["source_type"] == "scholarship"


@pytest.mark.asyncio
async def test_list_incomes(auth_client: AsyncClient):
    await auth_client.post("/api/v1/incomes/", json={
        "amount": "10000",
        "source_type": "freelance",
        "received_at": datetime.now(UTC).isoformat(),
    })
    resp = await auth_client.get("/api/v1/incomes/")
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


@pytest.mark.asyncio
async def test_create_expense(auth_client: AsyncClient):
    resp = await auth_client.post("/api/v1/expenses/", json={
        "amount": "5000",
        "category": "food",
        "spent_at": datetime.now(UTC).isoformat(),
        "merchant_name": "Test Cafe",
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["category"] == "food"


@pytest.mark.asyncio
async def test_list_expenses(auth_client: AsyncClient):
    await auth_client.post("/api/v1/expenses/", json={
        "amount": "3000",
        "category": "transport",
        "spent_at": datetime.now(UTC).isoformat(),
    })
    resp = await auth_client.get("/api/v1/expenses/")
    assert resp.status_code == 200
    assert len(resp.json()) >= 1


@pytest.mark.asyncio
async def test_update_expense(auth_client: AsyncClient):
    create = await auth_client.post("/api/v1/expenses/", json={
        "amount": "1000",
        "category": "other",
        "spent_at": datetime.now(UTC).isoformat(),
    })
    expense_id = create.json()["id"]
    resp = await auth_client.patch(f"/api/v1/expenses/{expense_id}", json={"amount": "1500"})
    assert resp.status_code == 200
    assert float(resp.json()["amount"]) == 1500


@pytest.mark.asyncio
async def test_delete_expense(auth_client: AsyncClient):
    create = await auth_client.post("/api/v1/expenses/", json={
        "amount": "500",
        "category": "other",
        "spent_at": datetime.now(UTC).isoformat(),
    })
    expense_id = create.json()["id"]
    resp = await auth_client.delete(f"/api/v1/expenses/{expense_id}")
    assert resp.status_code == 204
