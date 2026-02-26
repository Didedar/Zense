import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.suffixIcon,
    this.prefixIcon,
    this.onChanged,
    this.inputFormatters,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
          enabled: enabled,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}

class AmountInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? label;
  final String currency;
  final void Function(String)? onChanged;

  const AmountInputField({
    super.key,
    this.controller,
    this.validator,
    this.label,
    this.currency = 'KZT',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label ?? 'Сумма',
      hint: '0',
      controller: controller,
      validator: validator ?? _defaultValidator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text(
          currency,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ),
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) return 'Введите сумму';
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) return 'Сумма должна быть больше 0';
    return null;
  }
}
