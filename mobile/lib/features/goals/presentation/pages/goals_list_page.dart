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
        title: const Text('Quản lý Mục tiêu'),
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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.lg),
      color: goal.isPrimary
          ? AppColors.surfaceElevatedDark
          : AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(
          color: goal.isPrimary ? AppColors.primary : AppColors.borderDark,
          width: goal.isPrimary ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!goal.isPrimary) {
            ref.read(goalsProvider.notifier).setPrimaryGoal(goal.id);
          }
          context.push(AppRoutes.dashboard);
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Text(goal.emoji ?? '🎯',
                        style: const TextStyle(fontSize: 28)),
                  ),
                  const Gap(AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (goal.isPrimary)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Mục tiêu chính',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đã tích lũy',
                          style: Theme.of(context).textTheme.bodySmall),
                      const Gap(2),
                      Text(
                        CurrencyFormatter.format(goal.currentSavings),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Mục tiêu',
                          style: Theme.of(context).textTheme.bodySmall),
                      const Gap(2),
                      Text(
                        CurrencyFormatter.format(goal.targetAmount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(AppSizes.md),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceElevatedDark,
                color: AppColors.success,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const Gap(AppSizes.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Gap(AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}
