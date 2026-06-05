import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';

import 'package:fin_goal/features/goals/presentation/providers/goal_provider.dart';

class PaywallPage extends ConsumerWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsProvider);
    int currentActive = 0;
    if (goalsState is GoalsLoaded) {
      currentActive = goalsState.goals.where((g) => g.status != 'archived').length;
    }
    final singleSlotPrice = ref.watch(getGoalSlotPriceProvider(currentActive));
    final singlePriceStr = '${singleSlotPrice ~/ 1000}.000₫';

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
                        _buildFeatureRow(context, 'Tắt toàn bộ quảng cáo'),
                        _buildFeatureRow(context, 'Hỗ trợ ưu tiên 24/7'),

                        const Gap(AppSizes.xxl),

                        // Pricing Cards
                        _buildPricingCard(
                          context,
                          title: 'Mua thêm 1 Mục tiêu',
                          price: singlePriceStr,
                          subtitle: 'Thời hạn 1 năm',
                          isPopular: false,
                          onTap: () => _purchase(context, 'Mục tiêu lẻ', singlePriceStr),
                        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                        const Gap(AppSizes.md),

                        _buildPricingCard(
                          context,
                          title: 'Premium (Gói 6 Tháng)',
                          price: '199.000₫',
                          subtitle: 'Mở khóa mọi tính năng',
                          isPopular: false,
                          onTap: () => _purchase(context, 'Premium 6 Tháng', '199.000₫'),
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),

                        const Gap(AppSizes.md),

                        _buildPricingCard(
                          context,
                          title: 'Premium (Gói 1 Năm)',
                          price: '399.000₫',
                          subtitle: 'Tiết kiệm nhất',
                          isPopular: true,
                          onTap: () => _purchase(context, 'Premium 1 Năm', '399.000₫'),
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

  void _purchase(BuildContext context, String title, String price) {
    context.push('/home/payment', extra: {
      'title': title,
      'price': price,
    });
  }
}
