import uuid
from abc import ABC, abstractmethod
from datetime import UTC, datetime

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.ai_coach import AICoachEvent
from app.models.budget import BudgetPlan
from app.models.expense import Expense
from app.models.goal import Goal
from app.services.budget_service import get_safe_to_spend

DISCLAIMER = "This is educational & budgeting guidance, not financial advice."


class BaseCoach(ABC):
    @abstractmethod
    async def answer(self, db: AsyncSession, user_id: uuid.UUID, message: str, context: dict) -> dict:
        pass


class RuleBasedCoach(BaseCoach):
    INTENT_KEYWORDS = {
        "overspending": ["overspend", "too much", "spent a lot", "over budget", "broke"],
        "saving_goal": ["save", "goal", "saving", "target", "reach"],
        "budget_help": ["budget", "plan", "allocate", "spending plan"],
        "impulse_purchase": ["impulse", "want to buy", "should I buy", "tempted"],
        "confusion": ["how", "what", "help", "confused", "don't understand", "explain"],
    }

    RESPONSES = {
        "overspending": {
            "answer": "It looks like you might be spending more than planned. That's okay — awareness is the first step! Let's look at what adjustments we can make.",
            "actions": [
                {"action": "review_expenses", "description": "Review your recent expenses to find patterns"},
                {"action": "set_category_limits", "description": "Set stricter limits on your top spending categories"},
                {"action": "use_anti_impulse", "description": "Enable anti-impulse protection for shopping"},
            ],
            "confidence": 0.85,
        },
        "saving_goal": {
            "answer": "Saving for goals is awesome! Consistency matters more than amount. Even small contributions add up significantly over time.",
            "actions": [
                {"action": "check_goals", "description": "Review your current goal progress"},
                {"action": "increase_contribution", "description": "Try increasing your weekly goal contribution by 5%"},
                {"action": "automate_savings", "description": "Set up automatic contributions from each income"},
            ],
            "confidence": 0.80,
        },
        "budget_help": {
            "answer": "Let me help you with your budget! The key is finding a balance between needs, wants, and savings that works for your lifestyle.",
            "actions": [
                {"action": "generate_budget", "description": "Generate a fresh budget plan based on your profile"},
                {"action": "check_safe_to_spend", "description": "Check how much you can safely spend today"},
                {"action": "review_health", "description": "Run a budget health check"},
            ],
            "confidence": 0.85,
        },
        "impulse_purchase": {
            "answer": "Before buying, let's check: Is this a need or a want? Using the purchase impact simulator can show you exactly how this affects your goals.",
            "actions": [
                {"action": "use_simulator", "description": "Run a purchase impact simulation"},
                {"action": "wait_24h", "description": "Try the 24-hour rule — wait before deciding"},
                {"action": "start_anti_impulse", "description": "Start an anti-impulse session to mindfully decide"},
            ],
            "confidence": 0.90,
        },
        "confusion": {
            "answer": "No worries, I'm here to help! Zense helps you track spending, save for goals, and make smarter financial decisions. Ask me anything specific!",
            "actions": [
                {"action": "check_safe_to_spend", "description": "Start by checking your safe-to-spend amount"},
                {"action": "view_goals", "description": "Look at your savings goals"},
                {"action": "generate_budget", "description": "Create your first budget plan"},
            ],
            "confidence": 0.70,
        },
    }

    async def answer(self, db: AsyncSession, user_id: uuid.UUID, message: str, context: dict) -> dict:
        intent = self._detect_intent(message)
        response = self.RESPONSES.get(intent, self.RESPONSES["confusion"])
        return {
            "answer": response["answer"],
            "suggested_actions": response["actions"],
            "confidence": response["confidence"],
            "source": "rules",
            "disclaimer": DISCLAIMER,
        }

    def _detect_intent(self, message: str) -> str:
        lower = message.lower()
        best_intent = "confusion"
        best_score = 0
        for intent, keywords in self.INTENT_KEYWORDS.items():
            score = sum(1 for kw in keywords if kw in lower)
            if score > best_score:
                best_score = score
                best_intent = intent
        return best_intent


class LLMCoachStub(BaseCoach):
    async def answer(self, db: AsyncSession, user_id: uuid.UUID, message: str, context: dict) -> dict:
        if not settings.GEMINI_API_KEY:
            return {
                "answer": "LLM integration is not configured yet. Using rule-based coaching instead.",
                "suggested_actions": [],
                "confidence": 0.0,
                "source": "llm_stub",
                "disclaimer": DISCLAIMER,
            }

        try:
            from google import genai

            client = genai.Client(api_key=settings.GEMINI_API_KEY)
            prompt = (
                f"You are Zense, a friendly financial coach for Gen Z (16-20 years old). "
                f"Speak simply, warmly, no shaming. Give 1-3 concrete actions. "
                f"Context: {context}. "
                f"User question: {message}"
            )
            response = client.models.generate_content(
                model=settings.GEMINI_MODEL,
                contents=prompt,
            )
            return {
                "answer": response.text,
                "suggested_actions": [],
                "confidence": 0.75,
                "source": "llm",
                "disclaimer": DISCLAIMER,
            }
        except Exception:
            return {
                "answer": "I had trouble connecting to the AI service. Let me give you rule-based advice instead.",
                "suggested_actions": [],
                "confidence": 0.0,
                "source": "llm_error",
                "disclaimer": DISCLAIMER,
            }


class CoachOrchestrator:
    def __init__(self):
        self.rule_coach = RuleBasedCoach()
        self.llm_coach = LLMCoachStub()

    async def ask(self, db: AsyncSession, user_id: uuid.UUID, message: str) -> dict:
        context = await self._build_context(db, user_id)

        rule_result = await self.rule_coach.answer(db, user_id, message, context)

        if settings.GEMINI_API_KEY and rule_result["confidence"] < 0.75:
            llm_result = await self.llm_coach.answer(db, user_id, message, context)
            if llm_result["confidence"] > rule_result["confidence"]:
                result = llm_result
            else:
                result = rule_result
        else:
            result = rule_result

        event = AICoachEvent(
            user_id=user_id,
            event_type="question",
            input_payload={"message": message},
            output_payload=result,
        )
        db.add(event)
        await db.flush()

        return result

    async def get_latest_insights(self, db: AsyncSession, user_id: uuid.UUID) -> list[dict]:
        safe = await get_safe_to_spend(db, user_id)
        insights = []

        if safe["status"] == "risk":
            insights.append({
                "insight_type": "warning",
                "message": "Your budget is under pressure. Consider pausing non-essential spending.",
                "actions": ["Review recent expenses", "Postpone planned purchases"],
            })

        goals_result = await db.execute(
            select(Goal).where(and_(Goal.user_id == user_id, Goal.status == "active"))
        )
        for goal in goals_result.scalars().all():
            pct = float(goal.current_amount / goal.target_amount * 100) if goal.target_amount > 0 else 0
            if pct >= 80:
                insights.append({
                    "insight_type": "insight",
                    "message": f"Almost there! Your goal '{goal.title}' is {pct:.0f}% complete.",
                    "actions": ["Make a final contribution", "Plan your reward"],
                })

        if not insights:
            insights.append({
                "insight_type": "insight",
                "message": "Everything looks good! Keep following your budget plan.",
                "actions": ["Check your goals", "Review safe-to-spend"],
            })

        return insights

    async def _build_context(self, db: AsyncSession, user_id: uuid.UUID) -> dict:
        safe = await get_safe_to_spend(db, user_id)
        goals_result = await db.execute(
            select(Goal).where(and_(Goal.user_id == user_id, Goal.status == "active"))
        )
        goals = [{"title": g.title, "progress": float(g.current_amount / g.target_amount * 100) if g.target_amount > 0 else 0} for g in goals_result.scalars().all()]
        return {"safe_to_spend": safe, "active_goals": goals}


coach_orchestrator = CoachOrchestrator()
