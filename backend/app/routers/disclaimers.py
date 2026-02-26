from fastapi import APIRouter

from app.schemas.disclaimer import DISCLAIMERS, DisclaimerListResponse, DisclaimerRead

router = APIRouter(prefix="/disclaimers", tags=["Disclaimers"])


@router.get("/", response_model=DisclaimerListResponse)
async def list_disclaimers():
    return {
        "disclaimers": [
            DisclaimerRead(key=key, text=text) for key, text in DISCLAIMERS.items()
        ]
    }


@router.get("/{key}", response_model=DisclaimerRead)
async def get_disclaimer(key: str):
    text = DISCLAIMERS.get(key, DISCLAIMERS["general"])
    return DisclaimerRead(key=key, text=text)
