import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/money_utils.dart';

class MoneyText extends StatelessWidget {
  final dynamic amount;
  final String currency;
  final TextStyle? style;
  final bool showSign;
  final bool compact;

  const MoneyText({
    super.key,
    required this.amount,
    this.currency = 'KZT',
    this.style,
    this.showSign = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = MoneyUtils.parseAmount(amount);
    final formatted = compact
        ? MoneyUtils.formatCompact(amount, currency: currency)
        : MoneyUtils.format(amount, currency: currency);

    String display = formatted;
    Color? color;

    if (showSign) {
      if (value > 0) {
        display = '+$formatted';
        color = AppColors.income;
      } else if (value < 0) {
        color = AppColors.expense;
      }
    }

    return Text(
      display,
      style: (style ?? Theme.of(context).textTheme.bodyLarge)?.copyWith(
        color: color,
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label ?? _statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case 'good':
      case 'active':
      case 'completed':
        return AppColors.success;
      case 'warning':
      case 'at_risk':
        return AppColors.warning;
      case 'risk':
      case 'critical':
      case 'overspent':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'good':
        return 'В норме';
      case 'active':
        return 'Активно';
      case 'completed':
        return 'Выполнено';
      case 'warning':
        return 'Внимание';
      case 'at_risk':
        return 'Под угрозой';
      case 'risk':
      case 'critical':
        return 'Риск';
      case 'overspent':
        return 'Перерасход';
      default:
        return status;
    }
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (color ?? AppColors.primary).withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: color ?? AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class LoadingShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: const _ShimmerEffect(),
      ),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  const _ShimmerEffect();

  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * _controller.value, 0),
              end: Alignment(1.0 + 2 * _controller.value, 0),
              colors: const [
                AppColors.surfaceLight,
                AppColors.surfaceBorder,
                AppColors.surfaceLight,
              ],
            ),
          ),
        );
      },
    );
  }
}
