import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
                ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          ref.read(authProvider.notifier).signInWithGoogle();
                        },
                  icon: SvgPicture.string(
                    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.7 17.74 9.5 24 9.5z"/><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/><path fill="none" d="M0 0h48v48H0z"/></svg>''',
                    height: 20,
                    width: 20,
                  ),
                  label: const Text(
                    'Đăng nhập bằng Google',
                    style: TextStyle(
                      color: Color(0xFF1F1F1F),
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F1F1F),
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
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
