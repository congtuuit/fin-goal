import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fin_goal/app/router/routes.dart';
import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/goals/presentation/providers/goal_provider.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';
import 'package:fin_goal/core/presentation/widgets/banner_ad_widget.dart';

class GoalsListPage extends ConsumerWidget {
  const GoalsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsProvider);
    final isPremium = ref.watch(isPremiumUserProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing:
            16, // Use default padding for the left title since there's no custom icon on the left
        title: const Text('Mục tiêu tài chính'),
        actions: [
          if (!isPremium)
            TextButton.icon(
              icon: const Icon(Icons.diamond, color: AppColors.primary),
              label: const Text('Nâng cấp',
                  style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                context.push('/home/paywall');
              },
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                  child: Text('Premium',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold))),
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push(AppRoutes.profile);
            },
          ),
        ],
      ),
      body: goalsState is GoalsLoading
          ? const Center(child: CircularProgressIndicator())
          : goalsState is GoalsError
              ? Center(child: Text('Lỗi: ${goalsState.message}'))
              : _buildGoalsList(
                  context, ref, (goalsState as GoalsLoaded).goals, isPremium),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!isPremium &&
              (goalsState is GoalsLoaded && goalsState.goals.isNotEmpty)) {
            context.push('/home/paywall');
          } else {
            context.push('/home/goal-selection');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalsList(
      BuildContext context, WidgetRef ref, List<Goal> goals, bool isPremium) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bạn chưa có mục tiêu nào 🎯',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Gap(AppSizes.md),
            const Text('Hãy tạo một mục tiêu để bắt đầu.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppSizes.pageHorizontalPadding,
        right: AppSizes.pageHorizontalPadding,
        top: AppSizes.lg,
        bottom: 100, // For FAB
      ),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        return _buildGoalCard(context, ref, goal)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 100 * index))
            .slideY(begin: 0.1);
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Goal goal) {
    final progress = goal.targetAmount > 0
        ? (goal.currentSavings / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.lg),
      decoration: BoxDecoration(
        color: goal.isPrimary
            ? AppColors.surfaceElevatedDark
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: goal.isPrimary
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.borderDark,
          width: goal.isPrimary ? 1.5 : 1,
        ),
        boxShadow: goal.isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Stack(
          children: [
            // Watermark background
            Positioned(
              right: -20,
              bottom: -10,
              child: Opacity(
                opacity: 0.08,
                child: Text(
                  goal.emoji ?? '🎯',
                  style: const TextStyle(fontSize: 120),
                ),
              ),
            ),
            // Card Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (!goal.isPrimary) {
                    ref.read(goalsProvider.notifier).setPrimaryGoal(goal.id);
                  }
                  context.push(AppRoutes.dashboard);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.sm),
                            decoration: BoxDecoration(
                              color: goal.isPrimary
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.surfaceElevatedDark,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusMd),
                            ),
                            child: Text(goal.emoji ?? '🎯',
                                style: const TextStyle(fontSize: 24)),
                          ),
                          const Gap(AppSizes.md),
                          Expanded(
                            child: Text(
                              goal.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (goal.isPrimary)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.star_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const Gap(AppSizes.sm),
                      Text(
                        'Đã tích lũy',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const Gap(2),
                      Text(
                        CurrencyFormatter.format(goal.currentSavings),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                      ),
                      const Gap(AppSizes.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mục tiêu: ${CurrencyFormatter.format(goal.targetAmount)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * progress,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: AppColors.gradientPrimary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
