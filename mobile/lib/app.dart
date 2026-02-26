import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';

import 'features/home/presentation/screens/home_screen.dart';
import 'features/expenses/presentation/screens/expenses_list_screen.dart';
import 'features/expenses/presentation/screens/create_expense_screen.dart';
import 'features/incomes/presentation/screens/incomes_list_screen.dart';
import 'features/incomes/presentation/screens/create_income_screen.dart';
import 'features/goals/presentation/screens/goals_screens.dart';
import 'features/budgets/presentation/screens/budgets_screen.dart';
import 'features/simulator/presentation/screens/simulator_screen.dart';
import 'features/anti_impulse/presentation/screens/anti_impulse_screen.dart';
import 'features/coach/presentation/screens/coach_screen.dart';
import 'features/reports/presentation/screens/reports_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/quests/presentation/screens/quests_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Auth routes (no shell)
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/goals',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: GoalsListScreen()),
          ),
          GoRoute(
            path: '/coach',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CoachScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // Full-screen routes (outside shell)
      GoRoute(
          path: '/expenses', builder: (_, __) => const ExpensesListScreen()),
      GoRoute(
          path: '/expenses/create',
          builder: (_, __) => const CreateExpenseScreen()),
      GoRoute(path: '/incomes', builder: (_, __) => const IncomesListScreen()),
      GoRoute(
          path: '/incomes/create',
          builder: (_, __) => const CreateIncomeScreen()),
      GoRoute(
          path: '/goals/create', builder: (_, __) => const CreateGoalScreen()),
      GoRoute(
        path: '/goals/:id',
        builder: (_, state) =>
            GoalDetailScreen(goalId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/budgets', builder: (_, __) => const BudgetsScreen()),
      GoRoute(path: '/simulator', builder: (_, __) => const SimulatorScreen()),
      GoRoute(
        path: '/anti-impulse',
        builder: (_, __) => const AntiImpulseScreen(),
      ),
      GoRoute(
        path: '/anti-impulse/start',
        builder: (_, state) => AntiImpulseScreen(
          amount: double.tryParse(state.uri.queryParameters['amount'] ?? ''),
          category: state.uri.queryParameters['category'],
        ),
      ),
      GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
      GoRoute(path: '/quests', builder: (_, __) => const QuestsScreen()),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
    ],
  );
});

class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/goals')) return 1;
    if (location.startsWith('/coach')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(color: AppColors.surfaceBorder, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                    context, Icons.home_rounded, 'Главная', 0, index, '/home'),
                _navItem(
                    context, Icons.flag_rounded, 'Цели', 1, index, '/goals'),
                _addButton(context),
                _navItem(context, Icons.psychology_rounded, 'Коуч', 3, index,
                    '/coach'),
                _navItem(context, Icons.person_rounded, 'Профиль', 4, index,
                    '/profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label,
      int itemIndex, int currentIndex, String path) {
    final active = itemIndex == currentIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.go(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? AppColors.primary : AppColors.textTertiary,
                size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.textTertiary,
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddSheet(context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.add, color: AppColors.textOnPrimary, size: 28),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Добавить',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _addOption(ctx, Icons.remove_circle_outline, 'Расход',
                      AppColors.expense, '/expenses/create'),
                  _addOption(ctx, Icons.add_circle_outline, 'Доход',
                      AppColors.income, '/incomes/create'),
                  _addOption(ctx, Icons.calculate_outlined, 'Симулятор',
                      AppColors.primary, '/simulator'),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addOption(BuildContext context, IconData icon, String label,
      Color color, String path) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push(path);
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
