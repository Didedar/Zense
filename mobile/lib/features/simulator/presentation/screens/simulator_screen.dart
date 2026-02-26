import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/feature_providers.dart';
import '../../../../core/models/all_models.dart';

class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen> {
  final _amountController = TextEditingController();
  String _category = 'shopping';
  bool _isLoading = false;
  PurchaseImpactResponse? _result;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _simulate() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(featureApiProvider).simulatePurchase(
            amount: amount,
            category: _category,
          );
      setState(() {
        _result = result;
        _isLoading = false;
      });
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
      appBar: AppBar(title: const Text('Симулятор покупки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Что, если я куплю...? 🤔',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Узнай, как покупка повлияет на твой бюджет и цели',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            AmountInputField(
                controller: _amountController, label: 'Сумма покупки'),
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
              children: AppConstants.expenseCategories.map((c) {
                final emoji = AppConstants.categoryEmojis[c] ?? '📌';
                return CategoryChip(
                  category: '$emoji $c',
                  selected: _category == c,
                  onTap: () => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Посчитать влияние',
              onPressed: _simulate,
              isLoading: _isLoading,
              icon: Icons.calculate,
            ),
            if (_result != null) ...[
              const SizedBox(height: 32),
              _buildResult(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Safety indicator
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: r.isSafeNow
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: r.isSafeNow ? AppColors.success : AppColors.error,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                r.isSafeNow ? Icons.check_circle : Icons.warning_rounded,
                color: r.isSafeNow ? AppColors.success : AppColors.error,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.isSafeNow ? 'Покупка безопасна' : 'Покупка рискованна',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Safe-to-spend: ${MoneyUtils.format(r.safeToSpendToday)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Recommendation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡 Рекомендация',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(r.recommendation,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(r.reasoning, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        // Goal impacts
        if (r.goalImpacts.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Влияние на цели:',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...r.goalImpacts.map((gi) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(gi.goalTitle,
                            style: Theme.of(context).textTheme.titleMedium)),
                    Text(
                      gi.etaShiftDays > 0
                          ? '+${gi.etaShiftDays} дн'
                          : '${gi.etaShiftDays} дн',
                      style: TextStyle(
                        color: gi.etaShiftDays > 0
                            ? AppColors.error
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
        const SizedBox(height: 24),
        // CTAs
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Отложить',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  final amount = double.tryParse(_amountController.text);
                  if (amount != null) {
                    context.push(
                        '/anti-impulse/start?amount=$amount&category=$_category');
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Ок, куплю',
                onPressed: () {
                  context.push('/expenses/create');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
