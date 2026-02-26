import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GoalCard extends StatelessWidget {
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String? category;
  final String? status;
  final String? eta;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.category,
    this.status,
    this.eta,
    this.onTap,
  });

  double get _progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (status != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                          color: _statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.surfaceBorder,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${currentAmount.toStringAsFixed(0)} / ${targetAmount.toStringAsFixed(0)} KZT',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (eta != null) ...[
              const SizedBox(height: 4),
              Text(
                eta!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'at_risk':
        return AppColors.warning;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'completed':
        return 'Выполнено';
      case 'at_risk':
        return 'Под угрозой';
      case 'active':
        return 'Активно';
      case 'failed':
        return 'Не выполнено';
      default:
        return status ?? '';
    }
  }
}

class InsightCard extends StatelessWidget {
  final String message;
  final String? type;
  final List<String>? actions;
  final VoidCallback? onTap;

  const InsightCard({
    super.key,
    required this.message,
    this.type,
    this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (actions != null && actions!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: actions!
                          .map((a) => Chip(
                                label: Text(a,
                                    style: const TextStyle(fontSize: 11)),
                                backgroundColor: AppColors.surfaceLight,
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
