import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';

import '../../../../core/utils/money_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/providers/feature_providers.dart';
import '../../../../core/constants/app_constants.dart';

class ExpensesListScreen extends ConsumerWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Расходы')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        onPressed: () => context.push('/expenses/create'),
        child: const Icon(Icons.add),
      ),
      body: expenses.when(
        data: (list) {
          if (list.isEmpty) {
            return EmptyStateView(
              title: 'Пока нет расходов',
              subtitle: 'Добавь первый расход, чтобы начать отслеживать',
              icon: Icons.receipt_long_outlined,
              actionLabel: 'Добавить расход',
              onAction: () => context.push('/expenses/create'),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(expensesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final e = list[index];
                final emoji = AppConstants.categoryEmojis[e.category] ?? '📌';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 20))),
                    ),
                    title: Text(e.merchantName ?? e.category,
                        style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text(DateUtils2.formatRelative(e.spentAt),
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: Text(
                      '-${MoneyUtils.format(e.amount)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.expense),
                    ),
                    onTap: () => _showExpenseActions(context, ref, e.id),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorStateView(
          message: e.toString(),
          onRetry: () => ref.invalidate(expensesProvider),
        ),
      ),
    );
  }

  void _showExpenseActions(BuildContext context, WidgetRef ref, String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Редактировать'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/expenses/edit/$id');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Удалить',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(expensesProvider.notifier).delete(id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
