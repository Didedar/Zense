from fastapi import APIRouter, HTTPException, status

from app.core.deps import DbSession
from app.schemas.auth import TokenPair, TokenRefresh, UserLogin, UserRead, UserRegister
from app.services.auth_service import authenticate_user, generate_tokens, refresh_access_token, register_user
from app.core.deps import CurrentUser

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/register", response_model=TokenPair, status_code=status.HTTP_201_CREATED)
async def register(data: UserRegister, db: DbSession):
    try:
        user = await register_user(db, data.email, data.password, data.display_name)
        return generate_tokens(user.id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(e))


@router.post("/login", response_model=TokenPair)
async def login(data: UserLogin, db: DbSession):
    try:
        user = await authenticate_user(db, data.email, data.password)
        return generate_tokens(user.id)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))


@router.post("/refresh", response_model=TokenPair)
async def refresh(data: TokenRefresh, db: DbSession):
    try:
        return await refresh_access_token(db, data.refresh_token)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(e))


@router.get("/me", response_model=UserRead)
async def me(user: CurrentUser):
    return user
