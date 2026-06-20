import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/constants/app_config.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/app/router/routes.dart';

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

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhập email của bạn để nhận liên kết khôi phục mật khẩu.'),
              const SizedBox(height: AppSizes.md),
              TextFormField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => v != null && v.contains('@') ? null : 'Email không hợp lệ',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx);
                final error = await ref.read(authProvider.notifier).sendPasswordResetEmail(emailCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error ?? 'Đã gửi liên kết khôi phục. Vui lòng kiểm tra email.'),
                      backgroundColor: error == null ? AppColors.success : AppColors.danger,
                    ),
                  );
                }
              }
            },
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
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
                _LoginHeader(isOffline: isOffline),
                const SizedBox(height: AppSizes.xl),
                if (isOffline)
                  _buildOfflineInput()
                else
                  _buildOnlineInputs(),
                const SizedBox(height: AppSizes.xl),
                _LoginActions(
                  isOffline: isOffline,
                  isLoading: isLoading,
                  onSubmit: _submit,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineInput() {
    return TextFormField(
      controller: _nameCtrl,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      decoration: const InputDecoration(
        labelText: 'Họ và tên của bạn',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Vui lòng nhập tên của bạn',
    );
  }

  Widget _buildOnlineInputs() {
    return Column(
      children: [
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPasswordDialog,
            child: const Text('Quên mật khẩu?'),
          ),
        ),
      ],
    );
  }
}

class _LoginHeader extends StatelessWidget {
  final bool isOffline;
  const _LoginHeader({required this.isOffline});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }
}

class _LoginActions extends StatelessWidget {
  final bool isOffline;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _LoginActions({
    required this.isOffline,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: isLoading ? null : onSubmit,
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isOffline ? 'Bắt đầu ngay' : 'Đăng nhập'),
        ),
        const SizedBox(height: AppSizes.md),
        if (!isOffline)
          Center(
            child: TextButton(
              onPressed: () => context.push(AppRoutes.register),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ),
      ],
    );
  }
}
