from datetime import date

from pydantic import BaseModel


class PaginationParams(BaseModel):
    skip: int = 0
    limit: int = 50


class DateRangeParams(BaseModel):
    date_from: date | None = None
    date_to: date | None = None


class APIResponse(BaseModel):
    success: bool = True
    message: str = "OK"
    data: dict | list | None = None


class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    detail: str | None = None
