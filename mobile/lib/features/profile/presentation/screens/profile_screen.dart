import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/profile_api_service.dart';
import '../../data/models/profile_models.dart';

final _profileApiProvider = Provider<ProfileApiService>((ref) {
  return ProfileApiService(ref.watch(dioClientProvider));
});

final profileProvider = FutureProvider.autoDispose<ProfileRead>((ref) {
  return ref.read(_profileApiProvider).getProfile();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Профиль')),
      body: profile.when(
        data: (p) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    p.displayName.isNotEmpty
                        ? p.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(p.displayName,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(_segmentLabel(p.segment),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              _settingsCard(context, [
                _settingRow(context, Icons.person_outline, 'Сегмент',
                    _segmentLabel(p.segment)),
                _settingRow(context, Icons.attach_money, 'Валюта', p.currency),
                _settingRow(
                    context, Icons.access_time, 'Часовой пояс', p.timezone),
                _settingRow(context, Icons.psychology, 'Стиль трат',
                    _styleLabel(p.spendingStyle)),
              ]),
              const SizedBox(height: 16),
              _settingsCard(context, [
                _settingRow(context, Icons.bar_chart, 'Расходы', null,
                    onTap: () => context.push('/expenses')),
                _settingRow(
                    context, Icons.account_balance_wallet, 'Доходы', null,
                    onTap: () => context.push('/incomes')),
                _settingRow(context, Icons.receipt_long, 'Отчёты', null,
                    onTap: () => context.push('/reports')),
              ]),
              const SizedBox(height: 16),
              _settingsCard(context, [
                _settingRow(
                    context, Icons.info_outline, 'О приложении', 'MVP v1.0'),
                _settingRow(context, Icons.shield_outlined, 'Приватность',
                    'Все данные защищены'),
              ]),
              const SizedBox(height: 24),
              AppButton(
                label: 'Выйти',
                variant: AppButtonVariant.ghost,
                icon: Icons.logout,
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Zense — образовательное приложение для управления бюджетом.\nНе является финансовой рекомендацией.',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Ошибка загрузки профиля',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              AppButton(
                label: 'Выйти',
                expanded: false,
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingRow(
      BuildContext context, IconData icon, String label, String? value,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            if (value != null)
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  String _segmentLabel(String s) {
    switch (s) {
      case 'student':
        return 'Студент';
      case 'freelancer':
        return 'Фрилансер';
      case 'part_time':
        return 'Подработка';
      case 'creator':
        return 'Креатор';
      default:
        return s;
    }
  }

  String _styleLabel(String s) {
    switch (s) {
      case 'chaotic':
        return 'Хаотичный';
      case 'medium':
        return 'Средний';
      case 'disciplined':
        return 'Дисциплинированный';
      default:
        return s;
    }
  }
}
