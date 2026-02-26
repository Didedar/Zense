import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/feature_api_service.dart';
import '../models/all_models.dart';
import 'core_providers.dart';

// ───────── API Service ─────────
final featureApiProvider = Provider<FeatureApiService>((ref) {
  return FeatureApiService(ref.watch(dioClientProvider));
});

// ───────── Expenses ─────────
final expensesProvider =
    AsyncNotifierProvider.autoDispose<ExpensesNotifier, List<ExpenseRead>>(
        ExpensesNotifier.new);

class ExpensesNotifier extends AutoDisposeAsyncNotifier<List<ExpenseRead>> {
  @override
  Future<List<ExpenseRead>> build() async {
    return ref.read(featureApiProvider).getExpenses();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await ref.read(featureApiProvider).createExpense(data);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }

  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    await ref.read(featureApiProvider).updateExpense(id, data);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(featureApiProvider).deleteExpense(id);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }
}

// ───────── Incomes ─────────
final incomesProvider =
    AsyncNotifierProvider.autoDispose<IncomesNotifier, List<IncomeRead>>(
        IncomesNotifier.new);

class IncomesNotifier extends AutoDisposeAsyncNotifier<List<IncomeRead>> {
  @override
  Future<List<IncomeRead>> build() async {
    return ref.read(featureApiProvider).getIncomes();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await ref.read(featureApiProvider).createIncome(data);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }

  Future<void> updateIncome(String id, Map<String, dynamic> data) async {
    await ref.read(featureApiProvider).updateIncome(id, data);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(featureApiProvider).deleteIncome(id);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }
}

// ───────── Goals ─────────
final goalsProvider =
    AsyncNotifierProvider.autoDispose<GoalsNotifier, List<GoalRead>>(
        GoalsNotifier.new);

class GoalsNotifier extends AutoDisposeAsyncNotifier<List<GoalRead>> {
  @override
  Future<List<GoalRead>> build() async {
    return ref.read(featureApiProvider).getGoals();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await ref.read(featureApiProvider).createGoal(data);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    await ref.read(featureApiProvider).updateGoal(id, data);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }

  Future<void> delete(String id) async {
    await ref.read(featureApiProvider).deleteGoal(id);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }

  Future<void> contribute(String id, double amount) async {
    await ref.read(featureApiProvider).contributeToGoal(id, amount);
    ref.invalidateSelf();
    ref.invalidate(safeToSpendProvider);
    ref.invalidate(currentBudgetProvider);
    ref.invalidate(budgetHealthProvider);
  }
}

// ───────── Safe to Spend ─────────
final safeToSpendProvider =
    FutureProvider.autoDispose<SafeToSpendResponse>((ref) {
  return ref.read(featureApiProvider).getSafeToSpend();
});

// ───────── Budget ─────────
final currentBudgetProvider = FutureProvider.autoDispose<BudgetPlanRead>((ref) {
  return ref.read(featureApiProvider).getCurrentBudget();
});

final budgetHealthProvider =
    FutureProvider.autoDispose<BudgetHealthCheck>((ref) {
  return ref.read(featureApiProvider).getBudgetHealthCheck();
});

// ───────── Coach Insight ─────────
final latestInsightProvider = FutureProvider.autoDispose<CoachInsight>((ref) {
  return ref.read(featureApiProvider).getLatestInsight();
});

// ───────── Weekly Report ─────────
final latestReportProvider =
    FutureProvider.autoDispose<WeeklyReportRead>((ref) {
  return ref.read(featureApiProvider).getLatestWeeklyReport();
});

// ───────── Anti-Impulse History ─────────
final antiImpulseHistoryProvider =
    FutureProvider.autoDispose<List<AntiImpulseSessionRead>>((ref) {
  return ref.read(featureApiProvider).getAntiImpulseHistory();
});

// ───────── XP ─────────
final xpOverviewProvider = FutureProvider.autoDispose<XPOverview>((ref) {
  return ref.read(featureApiProvider).getXPOverview();
});

final xpHistoryProvider = FutureProvider.autoDispose<XPHistoryResponse>((ref) {
  return ref.read(featureApiProvider).getXPHistory();
});

// ───────── Quests ─────────
final questsProvider =
    AsyncNotifierProvider.autoDispose<QuestsNotifier, QuestListResponse>(
        QuestsNotifier.new);

class QuestsNotifier extends AutoDisposeAsyncNotifier<QuestListResponse> {
  @override
  Future<QuestListResponse> build() async {
    return ref.read(featureApiProvider).getQuests();
  }

  Future<void> startQuest(String templateId) async {
    await ref.read(featureApiProvider).startQuest(templateId);
    ref.invalidateSelf();
    ref.invalidate(xpOverviewProvider);
  }
}

// ───────── Notifications ─────────
final notificationsProvider = AsyncNotifierProvider.autoDispose<
    NotificationsNotifier, NotificationListResponse>(NotificationsNotifier.new);

class NotificationsNotifier
    extends AutoDisposeAsyncNotifier<NotificationListResponse> {
  @override
  Future<NotificationListResponse> build() async {
    return ref.read(featureApiProvider).getNotifications();
  }

  Future<void> markRead(List<String> ids) async {
    await ref.read(featureApiProvider).markNotificationsRead(ids);
    ref.invalidateSelf();
  }

  Future<void> markAllRead() async {
    await ref.read(featureApiProvider).markAllNotificationsRead();
    ref.invalidateSelf();
  }
}

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.read(featureApiProvider).getUnreadNotificationCount();
});

// ───────── Disclaimers ─────────
final disclaimersProvider =
    FutureProvider.autoDispose<List<DisclaimerRead>>((ref) {
  return ref.read(featureApiProvider).getDisclaimers();
});
