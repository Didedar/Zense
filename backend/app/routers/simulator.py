from fastapi import APIRouter

from app.core.deps import CurrentUser, DbSession
from app.schemas.simulator import PurchaseImpactRequest, PurchaseImpactResponse
from app.services.simulator_service import calculate_purchase_impact

router = APIRouter(prefix="/simulator", tags=["Impact Simulator"])


@router.post("/purchase-impact", response_model=PurchaseImpactResponse)
async def purchase_impact(data: PurchaseImpactRequest, user: CurrentUser, db: DbSession):
    result = await calculate_purchase_impact(db, user.id, data.purchase_amount, data.category, data.planned_date)
    return result
