import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/features/auth/presentation/widgets/google_sign_in_button.dart';

class LoginBottomSheet extends ConsumerWidget {
  final String title;
  final String subtitle;

  const LoginBottomSheet({
    super.key,
    this.title = 'Đăng nhập để tiếp tục',
    this.subtitle = 'Vui lòng liên kết với tài khoản Google để trải nghiệm đầy đủ tính năng.',
  });

  static Future<void> show(BuildContext context, {String? title, String? subtitle}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (context) => LoginBottomSheet(
        title: title ?? 'Đăng nhập để tiếp tục',
        subtitle: subtitle ?? 'Vui lòng liên kết với tài khoản Google để trải nghiệm đầy đủ tính năng.',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (_, next) {
      if (next is AuthSuccess) {
        // Đăng nhập thành công, đóng bottom sheet
        if (context.mounted) {
          context.pop();
        }
      } else if (next is AuthError) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message), backgroundColor: AppColors.danger),
          );
        }
      }
    });

    final authStatus = ref.watch(authProvider);
    final isLoading = authStatus is AuthLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.pageHorizontalPadding,
        right: AppSizes.pageHorizontalPadding,
        top: AppSizes.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_person_outlined, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),
          GoogleSignInButton(
            isLoading: isLoading,
            onPressed: () {
              ref.read(authProvider.notifier).signInWithGoogle();
            },
          ),
          const SizedBox(height: AppSizes.md),
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Để sau', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
