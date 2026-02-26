import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HeroStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String status;
  final IconData? icon;

  const HeroStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.status = 'good',
    this.icon,
  });

  Color get _statusColor {
    switch (status) {
      case 'warning':
        return AppColors.warning;
      case 'risk':
      case 'critical':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _statusColor.withValues(alpha: 0.15),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: _statusColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: _statusColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  String get _statusLabel {
    switch (status) {
      case 'warning':
        return 'Осторожно';
      case 'risk':
      case 'critical':
        return 'Риск';
      default:
        return 'В норме';
    }
  }
}
