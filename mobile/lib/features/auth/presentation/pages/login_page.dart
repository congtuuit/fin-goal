import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fin_goal/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/app/router/routes.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authProvider);
    final hasGoogleHistory = ref.watch(hasLoggedInWithGoogleProvider);

    // Listen for success/error
    ref.listen(authProvider, (_, next) {
      if (next is AuthSuccess) {
        context.go(AppRoutes.home);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    });

    final isLoading = authStatus is AuthLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),

                // Conversational Header
                Text(
                  hasGoogleHistory ? 'Chào mừng trở lại! 👋' : 'Xin chào! 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  hasGoogleHistory
                      ? 'Đăng nhập bằng Google để tiếp tục hành trình tài chính của bạn.'
                      : 'Trợ lý AI nên xưng hô với bạn thế nào?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.start,
                ),
                
                if (!hasGoogleHistory) ...[
                  const SizedBox(height: AppSizes.xxl),
                  
                  // Big Name Input
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tên hoặc biệt danh...',
                      hintStyle: TextStyle(fontSize: 24, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                    onChanged: (val) {
                      if (_errorMessage != null && val.trim().isNotEmpty) {
                        setState(() => _errorMessage = null);
                        _formKey.currentState?.validate();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '';
                      }
                      return null;
                    },
                  ),
                  
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                ],
                
                const Spacer(flex: 2),
                
                if (!hasGoogleHistory) ...[
                  // Start Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _errorMessage = null);
                                ref
                                    .read(authProvider.notifier)
                                    .signInWithName(_nameCtrl.text.trim());
                              } else {
                                setState(() => _errorMessage = 'Bạn chưa nhập tên kìa!');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Bắt đầu ngay',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                ],
                
                // Google Sync Button
                GoogleSignInButton(
                  isLoading: isLoading,
                  onPressed: () {
                    ref.read(authProvider.notifier).signInWithGoogle();
                  },
                ),
                
                const SizedBox(height: AppSizes.xxl),
              ],
            ),
          ),
        ),
      ),
    ],
  ),
),
    );
  }
}
