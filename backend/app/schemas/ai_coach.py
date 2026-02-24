from pydantic import BaseModel


class CoachAskRequest(BaseModel):
    user_message: str


class SuggestedAction(BaseModel):
    action: str
    description: str


class CoachAskResponse(BaseModel):
    answer: str
    suggested_actions: list[SuggestedAction]
    confidence: float
    source: str
    disclaimer: str = "This is educational & budgeting guidance, not financial advice."


class CoachInsight(BaseModel):
    insight_type: str
    message: str
    actions: list[str]
