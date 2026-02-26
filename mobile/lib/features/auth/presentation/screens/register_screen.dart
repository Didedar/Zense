import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authNotifierProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.error!), backgroundColor: AppColors.error),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: AppColors.textPrimary),
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Создать аккаунт',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Начни управлять финансами уже сегодня',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Имя',
                  hint: 'Как тебя зовут?',
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Введите имя' : null,
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  hint: 'example@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите email';
                    if (!v.contains('@')) return 'Некорректный email';
                    return null;
                  },
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Пароль',
                  hint: 'Минимум 6 символов',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите пароль';
                    if (v.length < 6) return 'Минимум 6 символов';
                    return null;
                  },
                  prefixIcon: const Icon(Icons.lock_outlined,
                      color: AppColors.textTertiary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Зарегистрироваться',
                  onPressed: _submit,
                  isLoading: authState.status == AuthStatus.loading,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: RichText(
                      text: TextSpan(
                        text: 'Уже есть аккаунт? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        children: [
                          TextSpan(
                            text: 'Войти',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Это образовательное приложение для управления бюджетом. Не является финансовой рекомендацией.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
