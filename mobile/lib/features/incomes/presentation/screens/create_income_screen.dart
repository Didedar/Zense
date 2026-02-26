import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/feature_providers.dart';

class CreateIncomeScreen extends ConsumerStatefulWidget {
  const CreateIncomeScreen({super.key});

  @override
  ConsumerState<CreateIncomeScreen> createState() => _CreateIncomeScreenState();
}

class _CreateIncomeScreenState extends ConsumerState<CreateIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _sourceType = 'salary';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(incomesProvider.notifier).create({
        'amount': double.parse(_amountController.text),
        'source_type': _sourceType,
        'received_at': DateTime.now().toIso8601String(),
        if (_noteController.text.isNotEmpty) 'note': _noteController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Доход добавлен ✓'),
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
      appBar: AppBar(title: const Text('Новый доход')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmountInputField(controller: _amountController),
              const SizedBox(height: 20),
              Text('Источник',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.incomeSourceTypes.map((s) {
                  final emoji = AppConstants.categoryEmojis[s] ?? '💰';
                  return CategoryChip(
                    category: '$emoji $s',
                    selected: _sourceType == s,
                    onTap: () => setState(() => _sourceType = s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Заметка',
                hint: 'Откуда доход?',
                controller: _noteController,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              AppButton(
                  label: 'Добавить доход',
                  onPressed: _submit,
                  isLoading: _isLoading,
                  icon: Icons.add),
            ],
          ),
        ),
      ),
    );
  }
}
