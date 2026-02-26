import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/hero_stat_card.dart';
import '../../../../core/widgets/goal_card.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/xp_bar_widget.dart';
import '../../../../core/widgets/disclaimer_banner.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/providers/feature_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safeToSpend = ref.watch(safeToSpendProvider);
    final goals = ref.watch(goalsProvider);
    final budget = ref.watch(currentBudgetProvider);
    final insight = ref.watch(latestInsightProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(safeToSpendProvider);
            ref.invalidate(goalsProvider);
            ref.invalidate(currentBudgetProvider);
            ref.invalidate(latestInsightProvider);
            ref.invalidate(xpOverviewProvider);
            ref.invalidate(unreadNotificationCountProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.trending_up,
                          color: AppColors.textOnPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Zense',
                              style: Theme.of(context).textTheme.headlineSmall),
                          Text('Добрый день! 👋',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_outlined,
                              color: AppColors.textSecondary),
                          if (unreadCount.valueOrNull != null &&
                              unreadCount.valueOrNull! > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.expense,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${unreadCount.valueOrNull}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/budgets'),
                      icon: const Icon(Icons.account_balance_wallet_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // XP Progress Bar
                const XPBarWidget(),
                const SizedBox(height: 20),

                // Safe to Spend Hero
                safeToSpend.when(
                  data: (data) => Column(
                    children: [
                      HeroStatCard(
                        title: 'Безопасно тратить сегодня',
                        value: MoneyUtils.format(data.safeToSpendToday),
                        subtitle:
                            'Осталось ${data.remainingDays} дн • Бюджет: ${MoneyUtils.formatCompact(data.remainingFunBudget)}',
                        status: data.status,
                        icon: Icons.shield_outlined,
                      ),
                      if (data.fixedLocked > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.surfaceBorder.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.surfaceBorder
                                    .withValues(alpha: 0.8)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline,
                                  color: AppColors.textTertiary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Обязательные платежи',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                              const Spacer(),
                              Text(
                                MoneyUtils.format(data.fixedLocked),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  loading: () => const LoadingShimmer(height: 140),
                  error: (e, _) => ErrorStateView(
                    message: 'Не удалось загрузить',
                    onRetry: () => ref.invalidate(safeToSpendProvider),
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Actions
                Text('Быстрые действия',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    QuickActionButton(
                      icon: Icons.remove_circle_outline,
                      label: '+ Расход',
                      color: AppColors.expense,
                      onTap: () => context.push('/expenses/create'),
                    ),
                    QuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: '+ Доход',
                      color: AppColors.income,
                      onTap: () => context.push('/incomes/create'),
                    ),
                    QuickActionButton(
                      icon: Icons.calculate_outlined,
                      label: 'Симулятор',
                      onTap: () => context.push('/simulator'),
                    ),
                    QuickActionButton(
                      icon: Icons.timer_outlined,
                      label: 'Анти-импульс',
                      color: AppColors.warning,
                      onTap: () => context.push('/anti-impulse'),
                    ),
                    QuickActionButton(
                      icon: Icons.videogame_asset_outlined,
                      label: 'Квесты',
                      color: AppColors.income,
                      onTap: () => context.push('/quests'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Goal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Главная цель',
                        style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => context.go('/goals'),
                      child: const Text('Все'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                goals.when(
                  data: (list) {
                    if (list.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.flag_outlined,
                                color: AppColors.textTertiary, size: 32),
                            const SizedBox(height: 8),
                            Text('Ещё нет целей',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.push('/goals/create'),
                              child: const Text('Создать цель'),
                            ),
                          ],
                        ),
                      );
                    }
                    final mainGoal = list.first;
                    return GoalCard(
                      title: mainGoal.title,
                      targetAmount: mainGoal.targetAmount,
                      currentAmount: mainGoal.currentAmount,
                      status: mainGoal.status,
                      category: mainGoal.category,
                      onTap: () => context.push('/goals/${mainGoal.id}'),
                    );
                  },
                  loading: () => const LoadingShimmer(height: 100),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Budget Snapshot (3 Buckets Distribution)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Распределение',
                        style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => context.push('/budgets'),
                      child: const Text('Изменить'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                budget.when(
                  data: (b) => Row(
                    children: [
                      Expanded(
                        child: _DistributionCard(
                          title: 'Резерв',
                          amount: b.reservePlanned,
                          iconColor: AppColors.info,
                          icon: Icons.account_balance_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DistributionCard(
                          title: 'Цели',
                          amount: b.goalContributionPlanned,
                          iconColor: AppColors.primary,
                          icon: Icons.track_changes_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DistributionCard(
                          title: 'Свободные',
                          amount: b.flexiblePlanned,
                          iconColor: AppColors.success,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const LoadingShimmer(height: 110),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () => context.push('/budgets'),
                        icon: const Icon(Icons.add),
                        label: const Text('Создать бюджет'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // AI Insight
                Text('Совет от ИИ 💡',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                insight.when(
                  data: (i) => InsightCard(
                    message: i.message,
                    type: i.insightType,
                    actions: i.actions,
                    onTap: () => context.go('/coach'),
                  ),
                  loading: () => const LoadingShimmer(height: 80),
                  error: (_, __) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Советы появятся после добавления расходов',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Disclaimer
                const DisclaimerBanner(
                  text:
                      '⚠️ Zense — образовательный инструмент. Не является финансовой консультацией.',
                  compact: true,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color iconColor;
  final IconData icon;

  const _DistributionCard({
    required this.title,
    required this.amount,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              MoneyUtils.formatCompact(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
