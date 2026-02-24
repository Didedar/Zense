import uuid

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_register(client: AsyncClient):
    resp = await client.post("/api/v1/auth/register", json={
        "email": f"reg_{uuid.uuid4().hex[:8]}@zense.kz",
        "password": "securepass",
        "display_name": "New User",
    })
    assert resp.status_code == 201
    data = resp.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_register_duplicate(client: AsyncClient):
    email = f"dup_{uuid.uuid4().hex[:8]}@zense.kz"
    await client.post("/api/v1/auth/register", json={"email": email, "password": "pass", "display_name": "U"})
    resp = await client.post("/api/v1/auth/register", json={"email": email, "password": "pass", "display_name": "U"})
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_login(client: AsyncClient):
    email = f"login_{uuid.uuid4().hex[:8]}@zense.kz"
    await client.post("/api/v1/auth/register", json={"email": email, "password": "mypass", "display_name": "L"})
    resp = await client.post("/api/v1/auth/login", json={"email": email, "password": "mypass"})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient):
    email = f"wrong_{uuid.uuid4().hex[:8]}@zense.kz"
    await client.post("/api/v1/auth/register", json={"email": email, "password": "correct", "display_name": "W"})
    resp = await client.post("/api/v1/auth/login", json={"email": email, "password": "wrong"})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_me(auth_client: AsyncClient):
    resp = await auth_client.get("/api/v1/auth/me")
    assert resp.status_code == 200
    data = resp.json()
    assert "email" in data
    assert data["is_active"] is True


@pytest.mark.asyncio
async def test_refresh(client: AsyncClient):
    email = f"ref_{uuid.uuid4().hex[:8]}@zense.kz"
    reg = await client.post("/api/v1/auth/register", json={"email": email, "password": "pass", "display_name": "R"})
    refresh_token = reg.json()["refresh_token"]
    resp = await client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert resp.status_code == 200
    assert "access_token" in resp.json()
