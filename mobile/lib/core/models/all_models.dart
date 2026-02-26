class ExpenseRead {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final DateTime spentAt;
  final String? merchantName;
  final String? note;
  final bool isImpulseFlag;
  final DateTime createdAt;

  const ExpenseRead({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.spentAt,
    this.merchantName,
    this.note,
    required this.isImpulseFlag,
    required this.createdAt,
  });

  factory ExpenseRead.fromJson(Map<String, dynamic> json) => ExpenseRead(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        amount: (json['amount'] is String
                ? double.tryParse(json['amount'])
                : (json['amount'] as num?)?.toDouble()) ??
            0.0,
        category: json['category'] as String? ?? 'other',
        spentAt: DateTime.tryParse(json['spent_at']?.toString() ?? '') ??
            DateTime.now(),
        merchantName: json['merchant_name'] as String?,
        note: json['note'] as String?,
        isImpulseFlag: json['is_impulse_flag'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class IncomeRead {
  final String id;
  final String userId;
  final double amount;
  final String sourceType;
  final DateTime receivedAt;
  final String? note;
  final bool isRecurring;
  final String recurringPeriod;
  final DateTime createdAt;

  const IncomeRead({
    required this.id,
    required this.userId,
    required this.amount,
    required this.sourceType,
    required this.receivedAt,
    this.note,
    required this.isRecurring,
    required this.recurringPeriod,
    required this.createdAt,
  });

  factory IncomeRead.fromJson(Map<String, dynamic> json) => IncomeRead(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        amount: (json['amount'] is String
                ? double.tryParse(json['amount'])
                : (json['amount'] as num?)?.toDouble()) ??
            0.0,
        sourceType: json['source_type'] as String? ?? 'other',
        receivedAt: DateTime.tryParse(json['received_at']?.toString() ?? '') ??
            DateTime.now(),
        note: json['note'] as String?,
        isRecurring: json['is_recurring'] as bool? ?? false,
        recurringPeriod: json['recurring_period'] as String? ?? 'none',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class GoalRead {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String? targetDate;
  final int priority;
  final String status;
  final String category;
  final DateTime createdAt;

  const GoalRead({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.priority,
    required this.status,
    required this.category,
    required this.createdAt,
  });

  double get progress =>
      (targetAmount > 0 ? (currentAmount / targetAmount) : 0.0).clamp(0.0, 1.0);

  factory GoalRead.fromJson(Map<String, dynamic> json) => GoalRead(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        targetAmount: (json['target_amount'] is String
                ? double.tryParse(json['target_amount'])
                : (json['target_amount'] as num?)?.toDouble()) ??
            0.0,
        currentAmount: (json['current_amount'] is String
                ? double.tryParse(json['current_amount'])
                : (json['current_amount'] as num?)?.toDouble()) ??
            0.0,
        targetDate: json['target_date']?.toString(),
        priority: json['priority'] as int? ?? 3,
        status: json['status'] as String? ?? 'active',
        category: json['category'] as String? ?? 'custom',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class GoalProgress {
  final String goalId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final double remaining;
  final double percentComplete;
  final int? daysRemaining;
  final String? estimatedCompletionDate;
  final double? weeklyContributionNeeded;

  const GoalProgress({
    required this.goalId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.remaining,
    required this.percentComplete,
    this.daysRemaining,
    this.estimatedCompletionDate,
    this.weeklyContributionNeeded,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> json) => GoalProgress(
        goalId: json['goal_id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
        remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
        percentComplete:
            ((json['target_amount'] as num?)?.toDouble() ?? 0.0) > 0
                ? ((json['percent_complete'] as num?)?.toDouble() ?? 0.0)
                : 0.0,
        daysRemaining: json['days_remaining'] as int?,
        estimatedCompletionDate: json['estimated_completion_date']?.toString(),
        weeklyContributionNeeded:
            (json['weekly_contribution_needed'] as num?)?.toDouble(),
      );
}

class SafeToSpendResponse {
  final double safeToSpendToday;
  final double fixedLocked;
  final double netAvailable;
  final double remainingFunBudget;
  final int remainingDays;
  final String status;
  final List<String> warnings;

  const SafeToSpendResponse({
    required this.safeToSpendToday,
    required this.fixedLocked,
    required this.netAvailable,
    required this.remainingFunBudget,
    required this.remainingDays,
    required this.status,
    required this.warnings,
  });

  factory SafeToSpendResponse.fromJson(Map<String, dynamic> json) {
    double _parse(dynamic val) {
      if (val is String) return double.tryParse(val) ?? 0.0;
      if (val is num) return val.toDouble();
      return 0.0;
    }

    return SafeToSpendResponse(
      safeToSpendToday: _parse(json['safe_to_spend_today']),
      fixedLocked: _parse(json['fixed_locked']),
      netAvailable: _parse(json['net_available']),
      remainingFunBudget: _parse(json['remaining_fun_budget']),
      remainingDays: json['remaining_days'] as int? ?? 0,
      status: json['status'] as String? ?? 'good',
      warnings: (json['warnings'] as List?)?.cast<String>() ?? [],
    );
  }
}

class BudgetPlanRead {
  final String id;
  final String userId;
  final String periodType;
  final String periodStart;
  final String periodEnd;
  final double totalIncomePlanned;
  final double goalContributionPlanned;
  final double reservePlanned;
  final double flexiblePlanned;
  final bool isActive;
  final DateTime createdAt;

  const BudgetPlanRead({
    required this.id,
    required this.userId,
    required this.periodType,
    required this.periodStart,
    required this.periodEnd,
    required this.totalIncomePlanned,
    required this.goalContributionPlanned,
    required this.reservePlanned,
    required this.flexiblePlanned,
    required this.isActive,
    required this.createdAt,
  });

  factory BudgetPlanRead.fromJson(Map<String, dynamic> json) {
    double _parse(dynamic val) {
      if (val is String) return double.tryParse(val) ?? 0.0;
      if (val is num) return val.toDouble();
      return 0.0;
    }

    return BudgetPlanRead(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      periodType: json['period_type'] as String? ?? 'weekly',
      periodStart: json['period_start']?.toString() ?? '',
      periodEnd: json['period_end']?.toString() ?? '',
      totalIncomePlanned: _parse(json['total_income_planned']),
      goalContributionPlanned: _parse(json['goal_contribution_planned']),
      reservePlanned: _parse(json['reserve_planned']),
      flexiblePlanned: _parse(json['flexible_planned']),
      isActive: json['is_active'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class BudgetHealthCheck {
  final String status;
  final int score;
  final List<String> reasons;
  final List<String> recommendations;

  const BudgetHealthCheck(
      {required this.status,
      required this.score,
      required this.reasons,
      required this.recommendations});

  factory BudgetHealthCheck.fromJson(Map<String, dynamic> json) =>
      BudgetHealthCheck(
        status: json['status'] as String? ?? 'good',
        score: json['score'] as int? ?? 0,
        reasons: (json['reasons'] as List?)?.cast<String>() ?? [],
        recommendations:
            (json['recommendations'] as List?)?.cast<String>() ?? [],
      );
}

class PurchaseImpactResponse {
  final bool isSafeNow;
  final double safeToSpendToday;
  final Map<String, dynamic> budgetImpact;
  final List<GoalImpact> goalImpacts;
  final String recommendation;
  final String reasoning;

  const PurchaseImpactResponse({
    required this.isSafeNow,
    required this.safeToSpendToday,
    required this.budgetImpact,
    required this.goalImpacts,
    required this.recommendation,
    required this.reasoning,
  });

  factory PurchaseImpactResponse.fromJson(Map<String, dynamic> json) =>
      PurchaseImpactResponse(
        isSafeNow: json['is_safe_now'] as bool? ?? false,
        safeToSpendToday:
            (json['safe_to_spend_today'] as num?)?.toDouble() ?? 0.0,
        budgetImpact: json['budget_impact'] as Map<String, dynamic>? ?? {},
        goalImpacts: (json['goal_impacts'] as List?)
                ?.map((e) => GoalImpact.fromJson(e))
                .toList() ??
            [],
        recommendation: json['recommendation'] as String? ?? '',
        reasoning: json['reasoning'] as String? ?? '',
      );
}

class GoalImpact {
  final String goalId;
  final String goalTitle;
  final int etaShiftDays;
  final String? newEstimatedDate;

  const GoalImpact(
      {required this.goalId,
      required this.goalTitle,
      required this.etaShiftDays,
      this.newEstimatedDate});

  factory GoalImpact.fromJson(Map<String, dynamic> json) => GoalImpact(
        goalId: json['goal_id']?.toString() ?? '',
        goalTitle: json['goal_title'] as String? ?? '',
        etaShiftDays: json['eta_shift_days'] as int? ?? 0,
        newEstimatedDate: json['new_estimated_date']?.toString(),
      );
}

class AntiImpulseStartResponse {
  final String sessionId;
  final int riskScore;
  final int cooldownSeconds;
  final int? goalImpactDays;
  final String recommendedIntervention;
  final String message;

  const AntiImpulseStartResponse({
    required this.sessionId,
    required this.riskScore,
    required this.cooldownSeconds,
    this.goalImpactDays,
    required this.recommendedIntervention,
    required this.message,
  });

  factory AntiImpulseStartResponse.fromJson(Map<String, dynamic> json) =>
      AntiImpulseStartResponse(
        sessionId: json['session_id']?.toString() ?? '',
        riskScore: json['risk_score'] as int? ?? 0,
        cooldownSeconds: json['cooldown_seconds'] as int? ?? 0,
        goalImpactDays: json['goal_impact_days'] as int?,
        recommendedIntervention:
            json['recommended_intervention'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );
}

class AntiImpulseSessionRead {
  final String id;
  final double plannedPurchaseAmount;
  final String category;
  final int riskScore;
  final int cooldownSeconds;
  final int? goalImpactDays;
  final String outcome;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const AntiImpulseSessionRead({
    required this.id,
    required this.plannedPurchaseAmount,
    required this.category,
    required this.riskScore,
    required this.cooldownSeconds,
    this.goalImpactDays,
    required this.outcome,
    required this.createdAt,
    this.resolvedAt,
  });

  factory AntiImpulseSessionRead.fromJson(Map<String, dynamic> json) =>
      AntiImpulseSessionRead(
        id: json['id']?.toString() ?? '',
        plannedPurchaseAmount:
            (json['planned_purchase_amount'] as num?)?.toDouble() ?? 0.0,
        category: json['category'] as String? ?? '',
        riskScore: json['risk_score'] as int? ?? 0,
        cooldownSeconds: json['cooldown_seconds'] as int? ?? 0,
        goalImpactDays: json['goal_impact_days'] as int?,
        outcome: json['outcome'] as String? ?? 'pending',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
        resolvedAt: json['resolved_at'] != null
            ? DateTime.tryParse(json['resolved_at'].toString())
            : null,
      );
}

class CoachAskResponse {
  final String answer;
  final List<SuggestedAction> suggestedActions;
  final double confidence;
  final String source;
  final String disclaimer;

  const CoachAskResponse({
    required this.answer,
    required this.suggestedActions,
    required this.confidence,
    required this.source,
    required this.disclaimer,
  });

  factory CoachAskResponse.fromJson(Map<String, dynamic> json) =>
      CoachAskResponse(
        answer: json['answer'] as String? ?? '',
        suggestedActions: (json['suggested_actions'] as List?)
                ?.map((e) => SuggestedAction.fromJson(e))
                .toList() ??
            [],
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        source: json['source'] as String? ?? '',
        disclaimer: json['disclaimer'] as String? ?? '',
      );
}

class SuggestedAction {
  final String action;
  final String description;

  const SuggestedAction({required this.action, required this.description});

  factory SuggestedAction.fromJson(Map<String, dynamic> json) =>
      SuggestedAction(
        action: json['action'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

class CoachInsight {
  final String insightType;
  final String message;
  final List<String> actions;

  const CoachInsight(
      {required this.insightType,
      required this.message,
      required this.actions});

  factory CoachInsight.fromJson(Map<String, dynamic> json) => CoachInsight(
        insightType: json['insight_type'] as String? ?? '',
        message: json['message'] as String? ?? '',
        actions: (json['actions'] as List?)?.cast<String>() ?? [],
      );
}

class WeeklyReportRead {
  final String id;
  final String userId;
  final String weekStart;
  final String weekEnd;
  final Map<String, dynamic> summaryJson;
  final String summaryText;
  final DateTime createdAt;

  const WeeklyReportRead({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.weekEnd,
    required this.summaryJson,
    required this.summaryText,
    required this.createdAt,
  });

  factory WeeklyReportRead.fromJson(Map<String, dynamic> json) =>
      WeeklyReportRead(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        weekStart: json['week_start']?.toString() ?? '',
        weekEnd: json['week_end']?.toString() ?? '',
        summaryJson: json['summary_json'] as Map<String, dynamic>? ?? {},
        summaryText: json['summary_text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

// ═══════════════ XP ═══════════════

class XPOverview {
  final int totalXp;
  final int level;
  final int streakDays;
  final int xpToNextLevel;
  final double levelProgressPercent;
  final DateTime? lastActionDate;

  const XPOverview({
    required this.totalXp,
    required this.level,
    required this.streakDays,
    required this.xpToNextLevel,
    required this.levelProgressPercent,
    this.lastActionDate,
  });

  factory XPOverview.fromJson(Map<String, dynamic> json) => XPOverview(
        totalXp: json['total_xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        streakDays: json['streak_days'] as int? ?? 0,
        xpToNextLevel: json['xp_to_next_level'] as int? ?? 500,
        levelProgressPercent:
            (json['level_progress_percent'] as num?)?.toDouble() ?? 0.0,
        lastActionDate: json['last_action_date'] != null
            ? DateTime.tryParse(json['last_action_date'].toString())
            : null,
      );
}

class XPTransactionRead {
  final String id;
  final String action;
  final int xpAmount;
  final String description;
  final String? sourceId;
  final DateTime createdAt;

  const XPTransactionRead({
    required this.id,
    required this.action,
    required this.xpAmount,
    required this.description,
    this.sourceId,
    required this.createdAt,
  });

  factory XPTransactionRead.fromJson(Map<String, dynamic> json) =>
      XPTransactionRead(
        id: json['id']?.toString() ?? '',
        action: json['action'] as String? ?? '',
        xpAmount: json['xp_amount'] as int? ?? 0,
        description: json['description'] as String? ?? '',
        sourceId: json['source_id']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class XPHistoryResponse {
  final List<XPTransactionRead> transactions;
  final int totalXp;
  final int level;

  const XPHistoryResponse({
    required this.transactions,
    required this.totalXp,
    required this.level,
  });

  factory XPHistoryResponse.fromJson(Map<String, dynamic> json) =>
      XPHistoryResponse(
        transactions: (json['transactions'] as List?)
                ?.map((e) => XPTransactionRead.fromJson(e))
                .toList() ??
            [],
        totalXp: json['total_xp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
      );
}

// ═══════════════ Quests ═══════════════

class QuestTemplateRead {
  final String id;
  final String slug;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final int xpReward;
  final int targetValue;
  final String actionType;
  final String iconEmoji;
  final bool isRepeatable;

  const QuestTemplateRead({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.xpReward,
    required this.targetValue,
    required this.actionType,
    required this.iconEmoji,
    required this.isRepeatable,
  });

  factory QuestTemplateRead.fromJson(Map<String, dynamic> json) =>
      QuestTemplateRead(
        id: json['id']?.toString() ?? '',
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'general',
        difficulty: json['difficulty'] as String? ?? 'easy',
        xpReward: json['xp_reward'] as int? ?? 0,
        targetValue: json['target_value'] as int? ?? 1,
        actionType: json['action_type'] as String? ?? '',
        iconEmoji: json['icon_emoji'] as String? ?? '🎯',
        isRepeatable: json['is_repeatable'] as bool? ?? false,
      );
}

class UserQuestRead {
  final String id;
  final String questTemplateId;
  final String status;
  final int currentValue;
  final int targetValue;
  final String title;
  final String description;
  final int xpReward;
  final String iconEmoji;
  final String difficulty;
  final double progressPercent;
  final DateTime startedAt;
  final DateTime? completedAt;

  const UserQuestRead({
    required this.id,
    required this.questTemplateId,
    required this.status,
    required this.currentValue,
    required this.targetValue,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.iconEmoji,
    required this.difficulty,
    required this.progressPercent,
    required this.startedAt,
    this.completedAt,
  });

  factory UserQuestRead.fromJson(Map<String, dynamic> json) => UserQuestRead(
        id: json['id']?.toString() ?? '',
        questTemplateId: json['quest_template_id']?.toString() ?? '',
        status: json['status'] as String? ?? 'active',
        currentValue: json['current_value'] as int? ?? 0,
        targetValue: json['target_value'] as int? ?? 1,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        xpReward: json['xp_reward'] as int? ?? 0,
        iconEmoji: json['icon_emoji'] as String? ?? '🎯',
        difficulty: json['difficulty'] as String? ?? 'easy',
        progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
        startedAt: DateTime.tryParse(json['started_at']?.toString() ?? '') ??
            DateTime.now(),
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'].toString())
            : null,
      );
}

class QuestListResponse {
  final List<UserQuestRead> active;
  final List<UserQuestRead> completed;
  final List<QuestTemplateRead> available;

  const QuestListResponse({
    required this.active,
    required this.completed,
    required this.available,
  });

  factory QuestListResponse.fromJson(Map<String, dynamic> json) =>
      QuestListResponse(
        active: (json['active'] as List?)
                ?.map((e) => UserQuestRead.fromJson(e))
                .toList() ??
            [],
        completed: (json['completed'] as List?)
                ?.map((e) => UserQuestRead.fromJson(e))
                .toList() ??
            [],
        available: (json['available'] as List?)
                ?.map((e) => QuestTemplateRead.fromJson(e))
                .toList() ??
            [],
      );
}

// ═══════════════ Micro-Lessons ═══════════════

class MicroLessonRead {
  final String id;
  final String slug;
  final String title;
  final String body;
  final String category;
  final String iconEmoji;
  final int xpReward;
  final int durationSeconds;

  const MicroLessonRead({
    required this.id,
    required this.slug,
    required this.title,
    required this.body,
    required this.category,
    required this.iconEmoji,
    required this.xpReward,
    required this.durationSeconds,
  });

  factory MicroLessonRead.fromJson(Map<String, dynamic> json) =>
      MicroLessonRead(
        id: json['id']?.toString() ?? '',
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? 'general',
        iconEmoji: json['icon_emoji'] as String? ?? '📚',
        xpReward: json['xp_reward'] as int? ?? 0,
        durationSeconds: json['duration_seconds'] as int? ?? 60,
      );
}

class MicroLessonTriggerResponse {
  final MicroLessonRead? lesson;
  final bool triggered;
  final String triggerReason;

  const MicroLessonTriggerResponse({
    this.lesson,
    required this.triggered,
    this.triggerReason = '',
  });

  factory MicroLessonTriggerResponse.fromJson(Map<String, dynamic> json) =>
      MicroLessonTriggerResponse(
        lesson: json['lesson'] != null
            ? MicroLessonRead.fromJson(json['lesson'])
            : null,
        triggered: json['triggered'] as bool? ?? false,
        triggerReason: json['trigger_reason'] as String? ?? '',
      );
}

// ═══════════════ Notifications ═══════════════

class NotificationRead {
  final String id;
  final String title;
  final String body;
  final String notificationType;
  final String? actionUrl;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;

  const NotificationRead({
    required this.id,
    required this.title,
    required this.body,
    required this.notificationType,
    this.actionUrl,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationRead.fromJson(Map<String, dynamic> json) =>
      NotificationRead(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        notificationType: json['notification_type'] as String? ?? 'info',
        actionUrl: json['action_url'] as String?,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
        isRead: json['is_read'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class NotificationListResponse {
  final List<NotificationRead> notifications;
  final int unreadCount;

  const NotificationListResponse({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) =>
      NotificationListResponse(
        notifications: (json['notifications'] as List?)
                ?.map((e) => NotificationRead.fromJson(e))
                .toList() ??
            [],
        unreadCount: json['unread_count'] as int? ?? 0,
      );
}

// ═══════════════ Disclaimers ═══════════════

class DisclaimerRead {
  final String key;
  final String text;

  const DisclaimerRead({required this.key, required this.text});

  factory DisclaimerRead.fromJson(Map<String, dynamic> json) => DisclaimerRead(
        key: json['key'] as String? ?? '',
        text: json['text'] as String? ?? '',
      );
}
