import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/providers/feature_providers.dart';
import '../../../../core/models/all_models.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(currentBudgetProvider);
    final health = ref.watch(budgetHealthProvider);
    final safeToSpend = ref.watch(safeToSpendProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Бюджет')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(currentBudgetProvider);
          ref.invalidate(budgetHealthProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Health check
              health.when(
                data: (h) => _healthCard(context, h),
                loading: () => const LoadingShimmer(height: 100),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              // Current budget
              budget.when(
                data: (b) => _budgetPlanCard(context, b, safeToSpend),
                loading: () => const LoadingShimmer(height: 200),
                error: (_, __) => Center(
                  child: Column(
                    children: [
                      const EmptyStateView(
                        title: 'Нет активного бюджета',
                        subtitle:
                            'Создай план, чтобы начать контролировать расходы',
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                      AppButton(
                        label: 'Сгенерировать план',
                        onPressed: () async {
                          try {
                            await ref
                                .read(featureApiProvider)
                                .generateBudgetPlan();
                            ref.invalidate(currentBudgetProvider);
                            ref.invalidate(budgetHealthProvider);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Ошибка: $e'),
                                    backgroundColor: AppColors.error),
                              );
                            }
                          }
                        },
                        icon: Icons.auto_awesome,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _healthCard(BuildContext context, BudgetHealthCheck h) {
    final statusColor = h.status == 'good'
        ? AppColors.success
        : h.status == 'warning'
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.1), AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Text('Здоровье бюджета',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              Text('${h.score}/100',
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ...h.recommendations.take(2).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(r,
                            style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _budgetPlanCard(BuildContext context, BudgetPlanRead b,
      AsyncValue<SafeToSpendResponse> safeToSpend) {
    int _percent(double amount) {
      if (b.totalIncomePlanned <= 0) return 0;
      return ((amount / b.totalIncomePlanned) * 100).round();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('План на ${b.periodType == "weekly" ? "неделю" : "месяц"}',
                  style: Theme.of(context).textTheme.titleLarge),
              StatusBadge(status: b.isActive ? 'active' : 'inactive'),
            ],
          ),
          const SizedBox(height: 4),
          Text('${b.periodStart} — ${b.periodEnd}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          if (b.periodType == 'weekly')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ваш подтвержденный доход за 30 дней разделен на 4 недели для удобного контроля.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _budgetRow(
              context,
              '💼 Доход на ${b.periodType == "weekly" ? "неделю" : "месяц"}',
              b.totalIncomePlanned),
          const Divider(height: 24),
          _budgetRow(
              context,
              '💸 Свободные деньги (План: ${MoneyUtils.formatCompact(b.flexiblePlanned)})',
              safeToSpend.valueOrNull?.remainingFunBudget ?? b.flexiblePlanned),
          _budgetRow(
              context,
              '🎯 На цели (${_percent(b.goalContributionPlanned)}%)',
              b.goalContributionPlanned),
          _budgetRow(context, '🛡️ Резерв (${_percent(b.reservePlanned)}%)',
              b.reservePlanned),
        ],
      ),
    );
  }

  Widget _budgetRow(BuildContext context, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          Text(MoneyUtils.format(amount),
              style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
