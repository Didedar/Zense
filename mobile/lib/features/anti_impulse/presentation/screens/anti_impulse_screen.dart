import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/utils/money_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/providers/feature_providers.dart';
import '../../../../core/models/all_models.dart';

class AntiImpulseScreen extends ConsumerStatefulWidget {
  final double? amount;
  final String? category;
  const AntiImpulseScreen({super.key, this.amount, this.category});

  @override
  ConsumerState<AntiImpulseScreen> createState() => _AntiImpulseScreenState();
}

class _AntiImpulseScreenState extends ConsumerState<AntiImpulseScreen> {
  AntiImpulseStartResponse? _session;
  // ignore: unused_field
  bool _isLoading = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _cooldownComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.amount != null && widget.category != null) {
      _startSession();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (widget.amount == null || widget.category == null) return;
    setState(() => _isLoading = true);
    try {
      final session = await ref.read(featureApiProvider).startAntiImpulse(
            amount: widget.amount!,
            category: widget.category!,
          );
      setState(() {
        _session = session;
        _remainingSeconds = session.cooldownSeconds;
        _isLoading = false;
      });
      _startCooldown();
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

  void _startCooldown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() => _cooldownComplete = true);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _resolve(String outcome) async {
    if (_session == null) return;
    try {
      await ref
          .read(featureApiProvider)
          .resolveAntiImpulse(_session!.sessionId, outcome);
      ref.invalidate(antiImpulseHistoryProvider);
      if (mounted) {
        final msg = outcome == 'cancelled'
            ? 'Отлично! Ты сэкономил 🎉'
            : outcome == 'postponed'
                ? 'Хорошо, подождём ещё'
                : 'Покупка совершена';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
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
      appBar: AppBar(title: const Text('Анти-Импульс')),
      body: _session == null ? _buildHistoryView() : _buildSessionView(),
    );
  }

  Widget _buildHistoryView() {
    final history = ref.watch(antiImpulseHistoryProvider);
    return history.when(
      data: (list) {
        if (list.isEmpty) {
          return const EmptyStateView(
            title: 'Нет сессий',
            subtitle: 'Используй симулятор, чтобы начать',
            icon: Icons.timer_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final s = list[index];
            return GestureDetector(
              onTap: s.outcome == 'pending'
                  ? () {
                      setState(() {
                        _session = AntiImpulseStartResponse(
                          sessionId: s.id,
                          riskScore: s.riskScore,
                          cooldownSeconds: s.cooldownSeconds,
                          goalImpactDays: s.goalImpactDays,
                          recommendedIntervention: 'Take a moment to think.',
                          message:
                              'Риск: ${s.riskScore}/100. Принимай решение взвешенно.',
                        );
                        final expiresAt = s.createdAt
                            .add(Duration(seconds: s.cooldownSeconds));
                        _remainingSeconds =
                            expiresAt.difference(DateTime.now()).inSeconds;
                        if (_remainingSeconds <= 0) {
                          _remainingSeconds = 0;
                          _cooldownComplete = true;
                        } else {
                          _cooldownComplete = false;
                          _startCooldown();
                        }
                      });
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: s.outcome == 'pending'
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Icon(_outcomeIcon(s.outcome),
                        color: _outcomeColor(s.outcome), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${s.category} • ${MoneyUtils.format(s.plannedPurchaseAmount)}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                              'Риск: ${s.riskScore}/100 • ${DateUtils2.formatRelative(s.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    StatusBadge(
                        status: s.outcome, label: _outcomeLabel(s.outcome)),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => ErrorStateView(
          message: e.toString(),
          onRetry: () => ref.invalidate(antiImpulseHistoryProvider)),
    );
  }

  Widget _buildSessionView() {
    final s = _session!;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Risk meter
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _riskColor(s.riskScore).withValues(alpha: 0.2),
                  AppColors.surface,
                ],
              ),
              border: Border.all(color: _riskColor(s.riskScore), width: 3),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${s.riskScore}',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: _riskColor(s.riskScore))),
                  const Text('Риск',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(s.message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // Cooldown timer
          if (!_cooldownComplete) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.timer, color: AppColors.warning, size: 32),
                  const SizedBox(height: 8),
                  Text('Подожди ещё',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text('⏰ Время вышло!',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Всё ещё хочешь купить?',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            AppButton(
                label: 'Нет, не буду ✓',
                onPressed: () => _resolve('cancelled')),
            const SizedBox(height: 12),
            AppButton(
                label: 'Подожду ещё',
                variant: AppButtonVariant.secondary,
                onPressed: () => _resolve('postponed')),
            const SizedBox(height: 12),
            AppButton(
                label: 'Всё-таки куплю',
                variant: AppButtonVariant.ghost,
                onPressed: () => _resolve('bought')),
          ],
        ],
      ),
    );
  }

  Color _riskColor(int score) {
    if (score < 30) return AppColors.success;
    if (score < 60) return AppColors.warning;
    return AppColors.error;
  }

  IconData _outcomeIcon(String o) {
    switch (o) {
      case 'cancelled':
        return Icons.check_circle;
      case 'postponed':
        return Icons.pause_circle;
      default:
        return Icons.shopping_bag;
    }
  }

  Color _outcomeColor(String o) {
    switch (o) {
      case 'cancelled':
        return AppColors.success;
      case 'postponed':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _outcomeLabel(String o) {
    switch (o) {
      case 'cancelled':
        return 'Отменено';
      case 'postponed':
        return 'Отложено';
      case 'bought':
        return 'Куплено';
      default:
        return 'Ожидание';
    }
  }
}
