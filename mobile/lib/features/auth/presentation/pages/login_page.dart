import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/constants/app_config.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (AppConfig.isOffline) {
      await ref.read(authProvider.notifier).signInWithName(
            _nameCtrl.text.trim(),
          );
    } else {
      await ref.read(authProvider.notifier).signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authProvider);
    final isOffline = AppConfig.isOffline;

    // Listen for success/error
    ref.listen(authProvider, (_, next) {
      if (next is AuthSuccess) {
        context.go('/home');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: AppColors.danger),
        );
        ref.read(authProvider.notifier).reset();
      }
    });

    final isLoading = authStatus is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                // Header
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  isOffline ? 'Chào mừng bạn' : 'Chào mừng trở lại',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  isOffline
                      ? 'Nhập tên của bạn để bắt đầu mô phỏng tài chính'
                      : 'Đăng nhập để xem kịch bản tài chính của bạn',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.xl),

                if (isOffline) ...[
                  // Name Input for Offline Mode
                  TextFormField(
                    controller: _nameCtrl,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên của bạn',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Vui lòng nhập tên của bạn',
                  ),
                ] else ...[
                  // Email & Password Inputs for Online Mode
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) => v != null && v.contains('@') ? null : 'Email không hợp lệ',
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v != null && v.length >= 6 ? null : 'Mật khẩu tối thiểu 6 ký tự',
                  ),
                ],
                const SizedBox(height: AppSizes.xl),

                // Submit button
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isOffline ? 'Bắt đầu ngay' : 'Đăng nhập'),
                ),
                const SizedBox(height: AppSizes.md),

                // Register link (Only show in online mode)
                if (!isOffline)
                  Center(
                    child: TextButton(
                      onPressed: () {/* TODO: navigate to register */},
                      child: const Text('Chưa có tài khoản? Đăng ký'),
                    ),
                  ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
