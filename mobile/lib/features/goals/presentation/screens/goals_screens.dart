import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/goal_card.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/providers/feature_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/all_models.dart';

class GoalsListScreen extends ConsumerWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Цели')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        onPressed: () => context.push('/goals/create'),
        child: const Icon(Icons.add),
      ),
      body: goals.when(
        data: (list) {
          if (list.isEmpty) {
            return EmptyStateView(
              title: 'Пока нет целей',
              subtitle: 'Создай цель и начни копить',
              icon: Icons.flag_outlined,
              actionLabel: 'Создать цель',
              onAction: () => context.push('/goals/create'),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(goalsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final g = list[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GoalCard(
                    title: g.title,
                    targetAmount: g.targetAmount,
                    currentAmount: g.currentAmount,
                    status: g.status,
                    category: g.category,
                    onTap: () => context.push('/goals/${g.id}'),
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
            onRetry: () => ref.invalidate(goalsProvider)),
      ),
    );
  }
}

class GoalDetailScreen extends ConsumerWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Цель')),
      body: goals.when(
        data: (list) {
          final goal = list.where((g) => g.id == goalId).firstOrNull;
          if (goal == null) {
            return const ErrorStateView(message: 'Цель не найдена');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.title,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                StatusBadge(status: goal.status),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Прогресс',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text('${(goal.progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          backgroundColor: AppColors.surfaceBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoColumn(context, 'Собрано',
                              MoneyUtils.format(goal.currentAmount)),
                          _infoColumn(context, 'Цель',
                              MoneyUtils.format(goal.targetAmount)),
                          _infoColumn(
                              context,
                              'Осталось',
                              MoneyUtils.format(
                                  goal.targetAmount - goal.currentAmount)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Внести вклад',
                  onPressed: () => _showContributeSheet(context, ref, goal),
                  icon: Icons.add,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Удалить цель',
                  variant: AppButtonVariant.ghost,
                  onPressed: () async {
                    await ref.read(goalsProvider.notifier).delete(goalId);
                    if (context.mounted) context.pop();
                  },
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => ErrorStateView(message: e.toString()),
      ),
    );
  }

  Widget _infoColumn(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  void _showContributeSheet(
      BuildContext context, WidgetRef ref, GoalRead goal) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Вклад в "${goal.title}"',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            AmountInputField(controller: controller, label: 'Сумма вклада'),
            const SizedBox(height: 20),
            AppButton(
              label: 'Внести',
              onPressed: () async {
                final amount = double.tryParse(controller.text);
                if (amount != null && amount > 0) {
                  Navigator.pop(ctx);
                  await ref
                      .read(goalsProvider.notifier)
                      .contribute(goal.id, amount);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Вклад внесён ✓'),
                          backgroundColor: AppColors.success),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'savings';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(goalsProvider.notifier).create({
        'title': _titleController.text,
        'target_amount': double.parse(_amountController.text),
        'category': _category,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Цель создана ✓'),
              backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Новая цель')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Название',
                hint: 'На что копишь?',
                controller: _titleController,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Введите название' : null,
              ),
              const SizedBox(height: 20),
              AmountInputField(
                  controller: _amountController, label: 'Целевая сумма'),
              const SizedBox(height: 20),
              Text('Категория',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.goalCategories.map((c) {
                  final emoji = AppConstants.categoryEmojis[c] ?? '⭐';
                  return CategoryChip(
                    category: '$emoji $c',
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              AppButton(
                  label: 'Создать цель',
                  onPressed: _submit,
                  isLoading: _isLoading,
                  icon: Icons.flag),
            ],
          ),
        ),
      ),
    );
  }
}
