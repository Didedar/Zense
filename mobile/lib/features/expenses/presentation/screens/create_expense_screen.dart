import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/feature_providers.dart';

class CreateExpenseScreen extends ConsumerStatefulWidget {
  const CreateExpenseScreen({super.key});

  @override
  ConsumerState<CreateExpenseScreen> createState() =>
      _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = 'food';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(expensesProvider.notifier).create({
        'amount': double.parse(_amountController.text),
        'category': _category,
        'spent_at': DateTime.now().toIso8601String(),
        if (_merchantController.text.isNotEmpty)
          'merchant_name': _merchantController.text,
        if (_noteController.text.isNotEmpty) 'note': _noteController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Расход добавлен ✓'),
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
      appBar: AppBar(title: const Text('Новый расход')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountInputField(controller: _amountController),
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
              const SizedBox(height: 20),
              AppTextField(
                label: 'Магазин / Сервис',
                hint: 'Где потратил?',
                controller: _merchantController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Заметка',
                hint: 'Зачем нужна была покупка?',
                controller: _noteController,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Добавить расход',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
