import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';

import '../../../../core/utils/money_utils.dart';
import '../../../../core/providers/feature_providers.dart';
import '../../../../core/models/all_models.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(latestReportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Недельный отчёт')),
      body: report.when(
        data: (r) => _buildReport(context, ref, r),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyStateView(
                title: 'Нет отчётов',
                subtitle: 'Сгенерируй первый недельный отчёт',
                icon: Icons.bar_chart_rounded,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AppButton(
                  label: 'Сгенерировать отчёт',
                  onPressed: () async {
                    try {
                      await ref.read(featureApiProvider).generateWeeklyReport();
                      ref.invalidate(latestReportProvider);
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReport(BuildContext context, WidgetRef ref, WeeklyReportRead r) {
    final summary = r.summaryJson;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.invalidate(latestReportProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r.weekStart} — ${r.weekEnd}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            // Summary text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.surface
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(r.summaryText,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 20),
            // Key metrics
            if (summary.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                      child: _metricCard(context, 'Доходы',
                          summary['total_income'] ?? 0, AppColors.income)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _metricCard(context, 'Расходы',
                          summary['total_expenses'] ?? 0, AppColors.expense)),
                ],
              ),
              const SizedBox(height: 12),
              // Top categories
              if (summary['top_categories'] is List) ...[
                Text('Топ категории расходов:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...(summary['top_categories'] as List).take(5).map((c) {
                  final cat = c is Map ? c : {};
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(cat['category']?.toString() ?? '—',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const Spacer(),
                        Text(MoneyUtils.format(cat['amount'] ?? 0),
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }),
              ],
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Сгенерировать новый',
              variant: AppButtonVariant.secondary,
              onPressed: () async {
                try {
                  await ref.read(featureApiProvider).generateWeeklyReport();
                  ref.invalidate(latestReportProvider);
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
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(
      BuildContext context, String label, dynamic amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(MoneyUtils.format(amount),
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
