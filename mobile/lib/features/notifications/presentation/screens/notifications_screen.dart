import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/providers/feature_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Уведомления 🔔'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Прочитать всё'),
          ),
        ],
      ),
      body: notifications.when(
        data: (data) {
          if (data.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔕', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('Пока нет уведомлений'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.notifications.length,
              itemBuilder: (context, index) {
                final n = data.notifications[index];
                return _NotificationTile(
                  title: n.title,
                  body: n.body,
                  type: n.notificationType,
                  isRead: n.isRead,
                  createdAt: n.createdAt,
                  onTap: () {
                    if (!n.isRead) {
                      ref.read(notificationsProvider.notifier).markRead([n.id]);
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(
          message: 'Не удалось загрузить',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case 'achievement':
        return Icons.emoji_events;
      case 'warning':
        return Icons.warning_amber;
      case 'alert':
        return Icons.error_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (type) {
      case 'achievement':
        return AppColors.income;
      case 'warning':
        return AppColors.warning;
      case 'alert':
        return AppColors.expense;
      default:
        return AppColors.primary;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} ч';
    return '${diff.inDays} дн';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? AppColors.surface
              : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? AppColors.surfaceBorder
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    fontWeight: isRead
                                        ? FontWeight.w400
                                        : FontWeight.w600)),
                      ),
                      Text(_timeAgo(),
                          style: TextStyle(
                              color: AppColors.textTertiary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (!isRead)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4),
                child:
                    CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
