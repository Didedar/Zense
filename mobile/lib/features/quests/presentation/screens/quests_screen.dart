import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/providers/feature_providers.dart';

class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Квесты 🎮'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(questsProvider),
        child: quests.when(
          data: (data) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active quests
                if (data.active.isNotEmpty) ...[
                  Text('Активные',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...data.active.map((q) => _QuestCard(
                        title: q.title,
                        description: q.description,
                        iconEmoji: q.iconEmoji,
                        difficulty: q.difficulty,
                        xpReward: q.xpReward,
                        currentValue: q.currentValue,
                        targetValue: q.targetValue,
                        progressPercent: q.progressPercent,
                        status: 'active',
                      )),
                  const SizedBox(height: 24),
                ],

                // Available quests
                if (data.available.isNotEmpty) ...[
                  Text('Доступные',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...data.available.map((q) => _AvailableQuestCard(
                        title: q.title,
                        description: q.description,
                        iconEmoji: q.iconEmoji,
                        difficulty: q.difficulty,
                        xpReward: q.xpReward,
                        targetValue: q.targetValue,
                        onStart: () =>
                            ref.read(questsProvider.notifier).startQuest(q.id),
                      )),
                  const SizedBox(height: 24),
                ],

                // Completed quests
                if (data.completed.isNotEmpty) ...[
                  Text('Выполнены ✅',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...data.completed.map((q) => _QuestCard(
                        title: q.title,
                        description: q.description,
                        iconEmoji: q.iconEmoji,
                        difficulty: q.difficulty,
                        xpReward: q.xpReward,
                        currentValue: q.currentValue,
                        targetValue: q.targetValue,
                        progressPercent: 100,
                        status: 'completed',
                      )),
                ],

                if (data.active.isEmpty &&
                    data.available.isEmpty &&
                    data.completed.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'Квесты скоро появятся!',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorStateView(
            message: 'Не удалось загрузить квесты',
            onRetry: () => ref.invalidate(questsProvider),
          ),
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final String title;
  final String description;
  final String iconEmoji;
  final String difficulty;
  final int xpReward;
  final int currentValue;
  final int targetValue;
  final double progressPercent;
  final String status;

  const _QuestCard({
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.difficulty,
    required this.xpReward,
    required this.currentValue,
    required this.targetValue,
    required this.progressPercent,
    required this.status,
  });

  Color get _difficultyColor {
    switch (difficulty) {
      case 'easy':
        return AppColors.income;
      case 'medium':
        return AppColors.warning;
      case 'hard':
        return AppColors.expense;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.income.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.income.withValues(alpha: 0.3)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(iconEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(description,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _difficultyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$xpReward XP',
                  style: TextStyle(
                    color: _difficultyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (progressPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppColors.income : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currentValue/$targetValue',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailableQuestCard extends StatelessWidget {
  final String title;
  final String description;
  final String iconEmoji;
  final String difficulty;
  final int xpReward;
  final int targetValue;
  final VoidCallback onStart;

  const _AvailableQuestCard({
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.difficulty,
    required this.xpReward,
    required this.targetValue,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Text(iconEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  'Цель: $targetValue • $xpReward XP',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Начать'),
          ),
        ],
      ),
    );
  }
}
