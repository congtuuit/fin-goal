import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_sizes.dart';

class AiExplanationCard extends StatelessWidget {
  final String? text;
  final bool isLoading;
  final VoidCallback? onRetry;

  const AiExplanationCard({
    super.key,
    this.text,
    this.isLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null && !isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              const Gap(AppSizes.sm),
              Text(
                'AI Phân tích',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const Gap(AppSizes.md),
          if (isLoading)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const Gap(AppSizes.sm),
                Text('Đang phân tích dữ liệu...', style: Theme.of(context).textTheme.bodyMedium),
              ],
            )
          else
            Text(
              text!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ).animate().fadeIn().moveY(begin: 10, end: 0, duration: 400.ms),
        ],
      ),
    ).animate().fadeIn();
  }
}
