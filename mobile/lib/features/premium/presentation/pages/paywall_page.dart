import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';

class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.backgroundDark, Color(0xFF1A1A24)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(AppSizes.pageHorizontalPadding),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.diamond_outlined,
                          size: 80,
                          color: AppColors.primary,
                        )
                            .animate()
                            .scale(delay: 200.ms, curve: Curves.easeOutBack),
                        const Gap(AppSizes.lg),
                        Text(
                          'Mở khóa toàn bộ\nsức mạnh của AI',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                        ).animate().fadeIn(delay: 300.ms),
                        const Gap(AppSizes.xl),

                        _buildFeatureRow(
                            context, 'Không giới hạn kịch bản "What-if"'),
                        _buildFeatureRow(
                            context, 'AI phân tích chuyên sâu mỗi tháng'),
                        _buildFeatureRow(
                            context, 'Tạo nhiều mục tiêu cùng lúc'),
                        _buildFeatureRow(context, 'Hỗ trợ ưu tiên 24/7'),

                        const Gap(AppSizes.xxl),

                        // Pricing Cards
                        _buildPricingCard(
                          context,
                          title: 'Gói Năm',
                          price: '599.000₫',
                          subtitle: 'Giảm 50% • chỉ 49.000₫ / tháng',
                          isPopular: true,
                          onTap: () => _purchase(context, ref),
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                        const Gap(AppSizes.md),

                        _buildPricingCard(
                          context,
                          title: 'Gói Tháng',
                          price: '99.000₫',
                          subtitle: 'thanh toán mỗi tháng',
                          isPopular: false,
                          onTap: () => _purchase(context, ref),
                        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
          const Gap(AppSizes.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 400.ms),
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String title,
    required String price,
    required String subtitle,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: BoxDecoration(
          color: isPopular
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          border: Border.all(
            color: isPopular ? AppColors.primary : AppColors.borderDark,
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isPopular
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                  ),
                ),
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(left: AppSizes.sm),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🔥 TỐT NHẤT',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Gap(AppSizes.md),
            Text(
              price,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(AppSizes.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16,
                    color: isPopular ? AppColors.primary : AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _purchase(BuildContext context, WidgetRef ref) {
    // Mock purchase flow
    ref.read(subscriptionProvider.notifier).upgradeToPremium();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nâng cấp Premium thành công! (Mock)'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }
}
