import '../../../core/network/dio_client.dart';
import '../../../core/models/all_models.dart';

class FeatureApiService {
  final DioClient _client;
  FeatureApiService(this._client);

  // ───────── Expenses ─────────
  Future<List<ExpenseRead>> getExpenses() async {
    final r = await _client.get('/expenses');
    return (r.data as List).map((e) => ExpenseRead.fromJson(e)).toList();
  }

  Future<ExpenseRead> createExpense(Map<String, dynamic> data) async {
    final r = await _client.post('/expenses', data: data);
    return ExpenseRead.fromJson(r.data);
  }

  Future<ExpenseRead> updateExpense(
      String id, Map<String, dynamic> data) async {
    final r = await _client.patch('/expenses/$id', data: data);
    return ExpenseRead.fromJson(r.data);
  }

  Future<void> deleteExpense(String id) async {
    await _client.delete('/expenses/$id');
  }

  // ───────── Incomes ─────────
  Future<List<IncomeRead>> getIncomes() async {
    final r = await _client.get('/incomes');
    return (r.data as List).map((e) => IncomeRead.fromJson(e)).toList();
  }

  Future<IncomeRead> createIncome(Map<String, dynamic> data) async {
    final r = await _client.post('/incomes', data: data);
    return IncomeRead.fromJson(r.data);
  }

  Future<IncomeRead> updateIncome(String id, Map<String, dynamic> data) async {
    final r = await _client.patch('/incomes/$id', data: data);
    return IncomeRead.fromJson(r.data);
  }

  Future<void> deleteIncome(String id) async {
    await _client.delete('/incomes/$id');
  }

  // ───────── Goals ─────────
  Future<List<GoalRead>> getGoals() async {
    final r = await _client.get('/goals');
    return (r.data as List).map((e) => GoalRead.fromJson(e)).toList();
  }

  Future<GoalRead> createGoal(Map<String, dynamic> data) async {
    final r = await _client.post('/goals', data: data);
    return GoalRead.fromJson(r.data);
  }

  Future<GoalRead> updateGoal(String id, Map<String, dynamic> data) async {
    final r = await _client.patch('/goals/$id', data: data);
    return GoalRead.fromJson(r.data);
  }

  Future<void> deleteGoal(String id) async {
    await _client.delete('/goals/$id');
  }

  Future<GoalRead> contributeToGoal(String id, double amount,
      {String source = 'manual', String? note}) async {
    final r = await _client.post('/goals/$id/contribute', data: {
      'amount': amount,
      'source': source,
      if (note != null) 'note': note,
    });
    return GoalRead.fromJson(r.data);
  }

  Future<GoalProgress> getGoalProgress(String id) async {
    final r = await _client.get('/goals/$id/progress');
    return GoalProgress.fromJson(r.data);
  }

  // ───────── Budgets ─────────
  Future<BudgetPlanRead> generateBudgetPlan(
      {String periodType = 'weekly'}) async {
    final r = await _client
        .post('/budgets/plan/generate', data: {'period_type': periodType});
    return BudgetPlanRead.fromJson(r.data);
  }

  Future<BudgetPlanRead> getCurrentBudget() async {
    final r = await _client.get('/budgets/current');
    return BudgetPlanRead.fromJson(r.data);
  }

  Future<SafeToSpendResponse> getSafeToSpend() async {
    final r = await _client.get('/budgets/safe-to-spend/today');
    return SafeToSpendResponse.fromJson(r.data);
  }

  Future<BudgetHealthCheck> getBudgetHealthCheck() async {
    final r = await _client.get('/budgets/health-check');
    return BudgetHealthCheck.fromJson(r.data);
  }

  // ───────── Simulator ─────────
  Future<PurchaseImpactResponse> simulatePurchase({
    required double amount,
    required String category,
    String? plannedDate,
  }) async {
    final r = await _client.post('/simulator/purchase-impact', data: {
      'purchase_amount': amount,
      'category': category,
      if (plannedDate != null) 'planned_date': plannedDate,
    });
    return PurchaseImpactResponse.fromJson(r.data);
  }

  // ───────── Anti-Impulse ─────────
  Future<AntiImpulseStartResponse> startAntiImpulse({
    required double amount,
    required String category,
  }) async {
    final r = await _client.post('/anti-impulse/start', data: {
      'planned_purchase_amount': amount,
      'category': category,
    });
    return AntiImpulseStartResponse.fromJson(r.data);
  }

  Future<void> resolveAntiImpulse(String sessionId, String outcome) async {
    await _client
        .post('/anti-impulse/$sessionId/resolve', data: {'outcome': outcome});
  }

  Future<List<AntiImpulseSessionRead>> getAntiImpulseHistory() async {
    final r = await _client.get('/anti-impulse/history');
    return (r.data as List)
        .map((e) => AntiImpulseSessionRead.fromJson(e))
        .toList();
  }

  // ───────── Coach ─────────
  Future<CoachAskResponse> askCoach(String message) async {
    final r =
        await _client.post('/ai/coach/ask', data: {'user_message': message});
    return CoachAskResponse.fromJson(r.data);
  }

  Future<CoachInsight> getLatestInsight() async {
    final r = await _client.get('/ai/coach/insights/latest');
    return CoachInsight.fromJson(r.data);
  }

  // ───────── Reports ─────────
  Future<WeeklyReportRead> generateWeeklyReport() async {
    final r = await _client.post('/reports/weekly/generate', data: {});
    return WeeklyReportRead.fromJson(r.data);
  }

  Future<WeeklyReportRead> getLatestWeeklyReport() async {
    final r = await _client.get('/reports/weekly/latest');
    return WeeklyReportRead.fromJson(r.data);
  }

  // ───────── Analytics ─────────
  Future<void> trackEvent(String eventName,
      {Map<String, dynamic>? payload}) async {
    try {
      await _client.post('/events/track', data: {
        'event_name': eventName,
        'event_payload': payload ?? {},
      });
    } catch (_) {
      // Best effort — don't break UX
    }
  }

  // ───────── XP ─────────
  Future<XPOverview> getXPOverview() async {
    final r = await _client.get('/xp/overview');
    return XPOverview.fromJson(r.data);
  }

  Future<XPHistoryResponse> getXPHistory({int limit = 50}) async {
    final r =
        await _client.get('/xp/history', queryParameters: {'limit': limit});
    return XPHistoryResponse.fromJson(r.data);
  }

  // ───────── Quests ─────────
  Future<QuestListResponse> getQuests() async {
    final r = await _client.get('/quests/');
    return QuestListResponse.fromJson(r.data);
  }

  Future<UserQuestRead> startQuest(String questTemplateId) async {
    final r = await _client.post('/quests/start', data: {
      'quest_template_id': questTemplateId,
    });
    return UserQuestRead.fromJson(r.data);
  }

  // ───────── Micro-Lessons ─────────
  Future<MicroLessonTriggerResponse> checkLessonTrigger(String event,
      {Map<String, dynamic>? context}) async {
    final r = await _client.post('/lessons/check-trigger', data: {
      'event': event,
      if (context != null) 'context': context,
    });
    return MicroLessonTriggerResponse.fromJson(r.data);
  }

  Future<Map<String, dynamic>> completeLesson(String lessonId) async {
    final r = await _client.post('/lessons/complete', data: {
      'lesson_id': lessonId,
    });
    return r.data as Map<String, dynamic>;
  }

  // ───────── Notifications ─────────
  Future<NotificationListResponse> getNotifications(
      {bool unreadOnly = false}) async {
    final r = await _client.get('/notifications/', queryParameters: {
      'unread_only': unreadOnly,
    });
    return NotificationListResponse.fromJson(r.data);
  }

  Future<int> getUnreadNotificationCount() async {
    final r = await _client.get('/notifications/unread-count');
    return (r.data as Map<String, dynamic>)['unread_count'] as int? ?? 0;
  }

  Future<void> markNotificationsRead(List<String> ids) async {
    await _client.post('/notifications/mark-read', data: {
      'notification_ids': ids,
    });
  }

  Future<void> markAllNotificationsRead() async {
    await _client.post('/notifications/mark-all-read');
  }

  // ───────── Disclaimers ─────────
  Future<List<DisclaimerRead>> getDisclaimers() async {
    final r = await _client.get('/disclaimers/');
    final list = (r.data as Map<String, dynamic>)['disclaimers'] as List;
    return list.map((e) => DisclaimerRead.fromJson(e)).toList();
  }

  Future<DisclaimerRead> getDisclaimer(String key) async {
    final r = await _client.get('/disclaimers/$key');
    return DisclaimerRead.fromJson(r.data);
  }
}
