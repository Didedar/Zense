import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Financial disclaimer banner widget
class DisclaimerBanner extends StatelessWidget {
  final String text;
  final bool compact;

  const DisclaimerBanner({
    super.key,
    required this.text,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: compact ? 14 : 16,
            color: AppColors.warning.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: compact ? 10 : 11,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
