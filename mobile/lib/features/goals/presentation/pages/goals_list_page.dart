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
import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';
// import 'package:fin_goal/core/presentation/widgets/banner_ad_widget.dart';

class GoalsListPage extends ConsumerWidget {
  const GoalsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsState = ref.watch(goalsProvider);
    final isPremium = ref.watch(isPremiumUserProvider);
    final profileState = ref.watch(profileProvider);

    int currentActive = 0;
    List<Goal> activeGoals = [];
    List<Goal> archivedGoals = [];
    if (goalsState is GoalsLoaded) {
      activeGoals =
          goalsState.goals.where((g) => g.status != 'archived').toList();
      archivedGoals =
          goalsState.goals.where((g) => g.status == 'archived').toList();
      currentActive = activeGoals.length;

      final now = DateTime.now();
      final toDelete = archivedGoals
          .where((g) => now.difference(g.updatedAt).inDays >= 7)
          .toList();
      if (toDelete.isNotEmpty) {
        archivedGoals.removeWhere((g) => toDelete.contains(g));
        Future.microtask(() {
          for (final goal in toDelete) {
            ref.read(goalsProvider.notifier).deleteGoal(goal.id);
          }
        });
      }
    }

    List<DateTime> purchasedSlots = [];
    if (profileState is ProfileLoaded && profileState.profile != null) {
      purchasedSlots = profileState.profile!.purchasedGoalSlots
          .where((expiry) => expiry.isAfter(DateTime.now()))
          .toList();
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 16,
          title: const Text('Mục tiêu tài chính'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đang thực hiện'),
              Tab(text: 'Đã xóa'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
          ),
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
                : TabBarView(
                    children: [
                      _buildActiveGoalsTab(context, ref, activeGoals, isPremium,
                          ref.watch(totalAllowedGoalsProvider), purchasedSlots),
                      _buildArchivedGoalsTab(context, ref, archivedGoals),
                    ],
                  ),
        floatingActionButton: currentActive >= 10
            ? null
            : FloatingActionButton(
                onPressed: () {
                  final canCreate =
                      ref.read(canCreateNewGoalProvider(currentActive));

                  if (!canCreate) {
                    context.push('/home/paywall');
                  } else {
                    context.push('/home/goal-selection');
                  }
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Widget _buildActiveGoalsTab(
      BuildContext context,
      WidgetRef ref,
      List<Goal> goals,
      bool isPremium,
      int totalAllowed,
      List<DateTime> purchasedSlots) {
    goals.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    if (goals.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pageHorizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Gap(AppSizes.xxl),
              const Text('🎯', style: TextStyle(fontSize: 80)),
              const Gap(AppSizes.lg),
              const Text(
                'Bạn chưa có mục tiêu nào',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Gap(AppSizes.md),
              Text(
                'Hãy tạo một mục tiêu để AI giúp bạn lập kế hoạch.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const Gap(AppSizes.xl),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Text(
                  '0 / $totalAllowed mục tiêu khả dụng',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Gap(AppSizes.xxl),
              _buildTrainingCampCard(context, isPremium),
            ],
          ),
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
      itemCount: goals.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách mục tiêu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedDark,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Text(
                    '${goals.length} / $totalAllowed',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (index == goals.length + 1) {
          return _buildTrainingCampCard(context, isPremium);
        }

        final goal = goals[index - 1];

        DateTime? expiryDate;
        int baseLimit = isPremium ? 10 : 2;
        int slotIndex = (index - 1) - baseLimit;
        if (slotIndex >= 0 && slotIndex < purchasedSlots.length) {
          expiryDate = purchasedSlots[slotIndex];
        }

        final isLocked = (index - 1) >= totalAllowed;

        return Dismissible(
          key: Key(goal.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.danger,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surfaceElevatedDark,
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                    Gap(AppSizes.sm),
                    Text('Xác nhận xóa'),
                  ],
                ),
                content: Text(
                    'Bạn có chắc chắn muốn xóa mục tiêu "${goal.name}" không? Mục tiêu này sẽ được chuyển vào Thùng rác trong 7 ngày trước khi bị xóa vĩnh viễn.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger),
                    child: const Text('Xóa',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            ref.read(goalsProvider.notifier).updateGoal(
                goal.copyWith(status: 'archived', updatedAt: DateTime.now()));
          },
          child: _buildGoalCard(context, ref, goal, expiryDate, isLocked)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index))
              .slideY(begin: 0.1),
        );
      },
    );
  }

  Widget _buildArchivedGoalsTab(
      BuildContext context, WidgetRef ref, List<Goal> archivedGoals) {
    if (archivedGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline,
                size: 80, color: AppColors.textMuted),
            const Gap(AppSizes.lg),
            Text(
              '',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Gap(AppSizes.sm),
            Text(
              'Các mục tiêu đã xóa sẽ nằm ở đây trong 7 ngày.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    archivedGoals.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppSizes.pageHorizontalPadding,
        right: AppSizes.pageHorizontalPadding,
        top: AppSizes.lg,
        bottom: 100,
      ),
      itemCount: archivedGoals.length,
      itemBuilder: (context, index) {
        final goal = archivedGoals[index];
        final daysLeft = 7 - DateTime.now().difference(goal.updatedAt).inDays;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSizes.lg),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.emoji ?? '🎯',
                      style: const TextStyle(fontSize: 24)),
                  const Gap(AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Sẽ bị xóa vĩnh viễn sau $daysLeft ngày',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(AppSizes.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surfaceElevatedDark,
                          title: const Text('Xóa vĩnh viễn'),
                          content: const Text(
                              'Bạn không thể khôi phục mục tiêu này sau khi xóa vĩnh viễn. Tiếp tục?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Hủy',
                                  style: TextStyle(color: AppColors.textMuted)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref
                                    .read(goalsProvider.notifier)
                                    .deleteGoal(goal.id);
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger),
                              child: const Text('Xóa vĩnh viễn',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_forever, size: 16),
                    label: const Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                  const Gap(AppSizes.sm),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(goalsProvider.notifier).updateGoal(goal.copyWith(
                          status: 'active', updatedAt: DateTime.now()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã khôi phục mục tiêu!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Khôi phục'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, Goal goal,
      DateTime? expiryDate, bool isLocked) {
    final progress = goal.targetAmount > 0
        ? (goal.currentSavings / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    String expectedDateText = '';
    if (goal.currentSavings >= goal.targetAmount) {
      expectedDateText = 'Đã hoàn thành 🎉';
    } else if (goal.monthlySaving > 0) {
      final remaining = goal.targetAmount - goal.currentSavings;
      final months = (remaining / goal.monthlySaving).ceil();
      final now = DateTime.now();
      final expected = DateTime(now.year, now.month + months);
      expectedDateText = 'Dự kiến: ${expected.month}/${expected.year}';
    } else {
      expectedDateText = 'Chưa có dòng tiền';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.lg),
      decoration: BoxDecoration(
        color: goal.isPinned
            ? AppColors.surfaceElevatedDark
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: goal.isPinned
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.borderDark,
          width: goal.isPinned ? 1.5 : 1,
        ),
        boxShadow: goal.isPinned
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
                  if (isLocked) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceElevatedDark,
                        title: const Row(
                          children: [
                            Icon(Icons.lock, color: AppColors.warning),
                            Gap(AppSizes.sm),
                            Text('Mục tiêu đã khóa'),
                          ],
                        ),
                        content: const Text(
                          'Mục tiêu này đã vượt quá giới hạn hoặc gói mua đã hết hạn. Nâng cấp lên Premium để mở khóa TẤT CẢ các mục tiêu ngay lập tức!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Để sau',
                                style: TextStyle(color: AppColors.textMuted)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push('/home/paywall');
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary),
                            child: const Text('Mở khóa Premium',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  if (!goal.isPrimary) {
                    ref.read(goalsProvider.notifier).setPrimaryGoal(goal.id);
                  }
                  context.push(AppRoutes.dashboard);
                },
                child: Opacity(
                  opacity: isLocked ? 0.5 : 1.0,
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
                                color: goal.isPinned
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
                                  if (expiryDate != null) ...[
                                    const Gap(4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Hết hạn: ${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Removed isPrimary star as requested to avoid duplicate stars
                            IconButton(
                              icon: Icon(
                                isLocked
                                    ? Icons.lock
                                    : (goal.isPinned
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded),
                                color: isLocked
                                    ? AppColors.warning
                                    : (goal.isPinned
                                        ? AppColors.primary
                                        : AppColors.textMuted),
                                size: 20,
                              ),
                              onPressed: () {
                                if (isLocked) return;
                                ref.read(goalsProvider.notifier).updateGoal(
                                      goal.copyWith(isPinned: !goal.isPinned),
                                    );
                              },
                            ),
                          ],
                        ),
                        const Gap(AppSizes.sm),
                        Text(
                          CurrencyFormatter.format(goal.currentSavings),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                        ),
                        const Gap(AppSizes.xs),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundDark,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        width: constraints.maxWidth * progress,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(3),
                                          gradient: AppColors.gradientPrimary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const Gap(AppSizes.md),
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Gap(AppSizes.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mục tiêu: ${CurrencyFormatter.format(goal.targetAmount)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                            Text(
                              expectedDateText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: expectedDateText.contains('Đã') 
                                      ? AppColors.success 
                                      : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingCampCard(BuildContext context, bool isPremium) {
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.lg, bottom: AppSizes.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primaryDark.withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          onTap: () {
            context.push(AppRoutes.cashflowBoardGame);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sports_esports,
                      color: AppColors.primary, size: 28),
                ),
                const Gap(AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trại huấn luyện Cashflow',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Gap(4),
                      Text(
                        'Học cách thoát khỏi vòng xoáy Rat Race.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Gap(AppSizes.sm),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
