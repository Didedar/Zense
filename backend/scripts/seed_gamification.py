"""
Seed script — populate quest templates, micro-lesson templates, and demo data.

Usage:
    cd backend && python -m scripts.seed_gamification
"""

import asyncio
import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import async_session_factory
from app.models.quest import QuestTemplate
from app.models.micro_lesson import MicroLesson


# ══════════════════════════════════════════════════════════════
# 12 QUEST TEMPLATES
# ══════════════════════════════════════════════════════════════
QUEST_TEMPLATES = [
    {
        "slug": "first-expense",
        "title": "Первый шаг 📝",
        "description": "Запишите свой первый расход",
        "category": "onboarding",
        "difficulty": "easy",
        "xp_reward": 50,
        "target_value": 1,
        "action_type": "expense_logged",
        "icon_emoji": "📝",
        "is_repeatable": False,
        "conditions": {},
    },
    {
        "slug": "track-5-expenses",
        "title": "Привычка трекинга 📊",
        "description": "Запишите 5 расходов",
        "category": "tracking",
        "difficulty": "easy",
        "xp_reward": 75,
        "target_value": 5,
        "action_type": "expense_logged",
        "icon_emoji": "📊",
        "is_repeatable": True,
        "conditions": {},
    },
    {
        "slug": "track-20-expenses",
        "title": "Мастер учёта 🏆",
        "description": "Запишите 20 расходов",
        "category": "tracking",
        "difficulty": "medium",
        "xp_reward": 200,
        "target_value": 20,
        "action_type": "expense_logged",
        "icon_emoji": "🏆",
        "is_repeatable": False,
        "conditions": {},
    },
    {
        "slug": "first-income",
        "title": "Первый доход 💰",
        "description": "Запишите свой первый доход",
        "category": "onboarding",
        "difficulty": "easy",
        "xp_reward": 50,
        "target_value": 1,
        "action_type": "income_logged",
        "icon_emoji": "💰",
        "is_repeatable": False,
        "conditions": {},
    },
    {
        "slug": "first-goal",
        "title": "Мечтатель 🎯",
        "description": "Создайте свою первую финансовую цель",
        "category": "onboarding",
        "difficulty": "easy",
        "xp_reward": 60,
        "target_value": 1,
        "action_type": "goal_created",
        "icon_emoji": "🎯",
        "is_repeatable": False,
        "conditions": {},
    },
    {
        "slug": "contribute-3-times",
        "title": "Копилка 🐷",
        "description": "Внесите на цель 3 раза",
        "category": "savings",
        "difficulty": "easy",
        "xp_reward": 100,
        "target_value": 3,
        "action_type": "goal_contribution",
        "icon_emoji": "🐷",
        "is_repeatable": True,
        "conditions": {},
    },
    {
        "slug": "complete-goal",
        "title": "Цель достигнута! 🏅",
        "description": "Достигните одну финансовую цель",
        "category": "savings",
        "difficulty": "hard",
        "xp_reward": 300,
        "target_value": 1,
        "action_type": "goal_completed",
        "icon_emoji": "🏅",
        "is_repeatable": True,
        "conditions": {},
    },
    {
        "slug": "anti-impulse-3",
        "title": "Железная воля 💪",
        "description": "Пройдите анти-импульс 3 раза и устойтесь",
        "category": "discipline",
        "difficulty": "medium",
        "xp_reward": 150,
        "target_value": 3,
        "action_type": "anti_impulse_skipped",
        "icon_emoji": "💪",
        "is_repeatable": True,
        "conditions": {},
    },
    {
        "slug": "create-budget",
        "title": "Планировщик 📋",
        "description": "Создайте свой первый бюджет",
        "category": "planning",
        "difficulty": "easy",
        "xp_reward": 80,
        "target_value": 1,
        "action_type": "budget_generated",
        "icon_emoji": "📋",
        "is_repeatable": False,
        "conditions": {},
    },
    {
        "slug": "simulator-5",
        "title": "Аналитик 🔮",
        "description": "Используйте симулятор 5 раз",
        "category": "analysis",
        "difficulty": "medium",
        "xp_reward": 120,
        "target_value": 5,
        "action_type": "simulator_used",
        "icon_emoji": "🔮",
        "is_repeatable": True,
        "conditions": {},
    },
    {
        "slug": "ask-coach-5",
        "title": "Любознательный 🤖",
        "description": "Задайте коучу 5 вопросов",
        "category": "learning",
        "difficulty": "easy",
        "xp_reward": 80,
        "target_value": 5,
        "action_type": "coach_asked",
        "icon_emoji": "🤖",
        "is_repeatable": True,
        "conditions": {},
    },
    {
        "slug": "income-3-sources",
        "title": "Диверсификатор 💸",
        "description": "Запишите доходы 3 раза",
        "category": "income",
        "difficulty": "medium",
        "xp_reward": 100,
        "target_value": 3,
        "action_type": "income_logged",
        "icon_emoji": "💸",
        "is_repeatable": True,
        "conditions": {},
    },
]


# ══════════════════════════════════════════════════════════════
# 12 MICRO-LESSON TEMPLATES
# ══════════════════════════════════════════════════════════════
MICRO_LESSONS = [
    {
        "slug": "impulse-buying-101",
        "title": "Что такое импульсивная покупка?",
        "body": (
            "Импульсивная покупка — это незапланированная трата, вызванная эмоциями. "
            "Исследования показывают, что до 40% расходов в онлайн-магазинах — импульсивные.\n\n"
            "💡 Совет: перед покупкой подождите 24 часа. Если утром всё ещё хотите — покупайте."
        ),
        "category": "behavior",
        "trigger_event": "expense_logged",
        "trigger_conditions": {"is_impulse": True},
        "icon_emoji": "🛒",
        "xp_reward": 15,
        "duration_seconds": 30,
    },
    {
        "slug": "budget-80-warning",
        "title": "Почему 80% бюджета — красная зона?",
        "body": (
            "Когда вы потратили 80% развлекательного бюджета, оставшихся 20% может не хватить "
            "на неожиданные удовольствия.\n\n"
            "💡 Правило: оставляйте буфер 20% на случай спонтанных возможностей."
        ),
        "category": "budgeting",
        "trigger_event": "budget_warning",
        "trigger_conditions": {},
        "icon_emoji": "⚠️",
        "xp_reward": 15,
        "duration_seconds": 30,
    },
    {
        "slug": "50-30-20-rule",
        "title": "Правило 50/30/20",
        "body": (
            "Классическое правило бюджетирования:\n"
            "• 50% — необходимое (жильё, еда, транспорт)\n"
            "• 30% — развлечения и хотелки\n"
            "• 20% — сбережения и цели\n\n"
            "💡 Zense адаптирует это правило под ваш сегмент и стиль трат."
        ),
        "category": "budgeting",
        "trigger_event": "budget_generated",
        "trigger_conditions": {},
        "icon_emoji": "📊",
        "xp_reward": 20,
        "duration_seconds": 45,
    },
    {
        "slug": "compound-interest",
        "title": "Магия сложного процента",
        "body": (
            "Если откладывать 10 000 ₸ в месяц под 10% годовых:\n"
            "• Через 1 год: ~126 000 ₸\n"
            "• Через 5 лет: ~775 000 ₸\n"
            "• Через 10 лет: ~2 050 000 ₸\n\n"
            "💡 Начните с малого — время на вашей стороне!"
        ),
        "category": "investing",
        "trigger_event": "goal_contribution",
        "trigger_conditions": {},
        "icon_emoji": "📈",
        "xp_reward": 20,
        "duration_seconds": 45,
    },
    {
        "slug": "emergency-fund",
        "title": "Зачем нужна финансовая подушка?",
        "body": (
            "Финансовая подушка — это 3-6 месячных расходов на случай непредвиденных ситуаций.\n\n"
            "Без подушки одна поломка машины или визит к врачу может привести к долгам.\n\n"
            "💡 Создайте цель «Подушка безопасности» и откладывайте хотя бы 5% дохода."
        ),
        "category": "savings",
        "trigger_event": "goal_created",
        "trigger_conditions": {},
        "icon_emoji": "🛡️",
        "xp_reward": 15,
        "duration_seconds": 40,
    },
    {
        "slug": "food-spending-tip",
        "title": "Как сократить расходы на еду?",
        "body": (
            "Еда — одна из крупнейших статей расходов:\n"
            "• Планируйте меню на неделю\n"
            "• Готовьте дома — экономия до 50%\n"
            "• Берите обед с собой\n"
            "• Покупайте по списку\n\n"
            "💡 Попробуйте неделю без доставки и посмотрите разницу!"
        ),
        "category": "spending",
        "trigger_event": "expense_logged",
        "trigger_conditions": {"category": "food"},
        "icon_emoji": "🍽️",
        "xp_reward": 15,
        "duration_seconds": 35,
    },
    {
        "slug": "subscription-audit",
        "title": "Аудит подписок",
        "body": (
            "Средний человек забывает о 2-3 подписках, которые тихо списывают деньги каждый месяц.\n\n"
            "💡 Проверьте: все ли подписки вы действительно используете? "
            "Отмените те, что не открывали больше месяца."
        ),
        "category": "spending",
        "trigger_event": "expense_logged",
        "trigger_conditions": {"category": "subscriptions"},
        "icon_emoji": "🔄",
        "xp_reward": 15,
        "duration_seconds": 30,
    },
    {
        "slug": "goal-milestone-50",
        "title": "Вы на полпути! 🎉",
        "body": (
            "Половина пути пройдена! Исследования показывают, что люди, которые достигают "
            "50% цели, завершают её в 80% случаев.\n\n"
            "💡 Не сбавляйте темп — финиш ближе, чем кажется!"
        ),
        "category": "motivation",
        "trigger_event": "goal_contribution",
        "trigger_conditions": {},
        "icon_emoji": "🎯",
        "xp_reward": 10,
        "duration_seconds": 20,
    },
    {
        "slug": "smart-shopping",
        "title": "Умный шоппинг",
        "body": (
            "Перед покупкой задайте 3 вопроса:\n"
            "1. Мне это НУЖНО или ХОЧЕТСЯ?\n"
            "2. Есть ли альтернатива дешевле?\n"
            "3. Буду ли я рад этой покупке через неделю?\n\n"
            "💡 Если ответ на вопрос 3 — нет, лучше пока отложить."
        ),
        "category": "behavior",
        "trigger_event": "expense_logged",
        "trigger_conditions": {"category": {"in": ["shopping", "entertainment"]}},
        "icon_emoji": "🧠",
        "xp_reward": 15,
        "duration_seconds": 30,
    },
    {
        "slug": "income-diversification",
        "title": "Диверсификация дохода",
        "body": (
            "Один источник дохода — это риск. Если он исчезнет, вы останетесь без средств.\n\n"
            "Идеи дополнительного дохода для Gen Z:\n"
            "• Фриланс (дизайн, тексты, разработка)\n"
            "• Продажа hand-made\n"
            "• Репетиторство\n"
            "• Контент-креатор\n\n"
            "💡 Начните с 1 часа в неделю на второй источник дохода."
        ),
        "category": "income",
        "trigger_event": "income_logged",
        "trigger_conditions": {},
        "icon_emoji": "💼",
        "xp_reward": 20,
        "duration_seconds": 45,
    },
    {
        "slug": "pay-yourself-first",
        "title": "Сначала заплати себе",
        "body": (
            "Главное правило богатых: сначала откладывай, потом трать.\n\n"
            "Как только получили доход, сразу переведите % на цель. "
            "Даже 5-10% дохода — это хорошее начало.\n\n"
            "💡 Автоматизируйте: настройте регулярный перевод в день зарплаты."
        ),
        "category": "savings",
        "trigger_event": "income_logged",
        "trigger_conditions": {},
        "icon_emoji": "🏦",
        "xp_reward": 15,
        "duration_seconds": 30,
    },
    {
        "slug": "transport-savings",
        "title": "Экономия на транспорте",
        "body": (
            "Транспорт может съедать до 15% бюджета:\n"
            "• Сравните: такси vs автобус vs велосипед\n"
            "• Попробуйте каршеринг вместо своего авто\n"
            "• Ходите пешком до 2 км — это ещё и полезно!\n\n"
            "💡 Посчитайте, сколько тратите на транспорт за месяц."
        ),
        "category": "spending",
        "trigger_event": "expense_logged",
        "trigger_conditions": {"category": "transport"},
        "icon_emoji": "🚌",
        "xp_reward": 15,
        "duration_seconds": 30,
    },
]


async def seed_all():
    async with async_session_factory() as db:
        # Seed quest templates
        for qt_data in QUEST_TEMPLATES:
            from sqlalchemy import select
            existing = await db.execute(
                select(QuestTemplate).where(QuestTemplate.slug == qt_data["slug"])
            )
            if not existing.scalar_one_or_none():
                db.add(QuestTemplate(**qt_data))
                print(f"  ✅ Quest: {qt_data['title']}")
            else:
                print(f"  ⏭️  Quest exists: {qt_data['title']}")

        # Seed micro-lessons
        for ml_data in MICRO_LESSONS:
            from sqlalchemy import select
            existing = await db.execute(
                select(MicroLesson).where(MicroLesson.slug == ml_data["slug"])
            )
            if not existing.scalar_one_or_none():
                db.add(MicroLesson(**ml_data))
                print(f"  ✅ Lesson: {ml_data['title']}")
            else:
                print(f"  ⏭️  Lesson exists: {ml_data['title']}")

        await db.commit()
        print("\n🎉 Seeding complete!")


if __name__ == "__main__":
    print("🌱 Seeding gamification data...")
    asyncio.run(seed_all())
