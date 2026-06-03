import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/goals/presentation/providers/goal_provider.dart';
import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_engine.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_input.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_result.dart';
import 'package:fin_goal/features/scenarios/domain/entities/monthly_record.dart';
import 'package:fin_goal/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';
import 'package:fin_goal/app/router/routes.dart';

class ScenarioDashboardPage extends ConsumerStatefulWidget {
  const ScenarioDashboardPage({super.key});

  @override
  ConsumerState<ScenarioDashboardPage> createState() =>
      _ScenarioDashboardPageState();
}

class _ScenarioDashboardPageState extends ConsumerState<ScenarioDashboardPage> {
  final _engine = const ScenarioEngine();

  // Local state for the slider
  int? _customMonthlySaving;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final goalsState = ref.watch(goalsProvider);

    // 1. Loading states
    if (profileState is ProfileLoading || goalsState is GoalsLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 2. Error states
    if (profileState is ProfileError) {
      return Scaffold(
          body: Center(child: Text('Lỗi: ${profileState.message}')));
    }
    if (goalsState is GoalsError) {
      return Scaffold(body: Center(child: Text('Lỗi: ${goalsState.message}')));
    }

    // 3. Ensure we have data
    final profile = (profileState as ProfileLoaded).profile;
    if (profile == null) {
      // Should not happen due to router redirect, but safe fallback
      return const Scaffold(body: Center(child: Text('Chưa có profile')));
    }

    final primaryGoal = (goalsState as GoalsLoaded).primaryGoal;
    if (primaryGoal == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go(AppRoutes.profile),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bạn chưa có mục tiêu nào 🎯',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Gap(AppSizes.md),
              const Text('Hãy tạo một mục tiêu để bắt đầu mô phỏng.'),
              const Gap(AppSizes.xl),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.buttonHeight),
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                ),
                onPressed: () => context.go('/home/goal-selection'),
                icon: const Icon(Icons.add),
                label: const Text('Tạo mục tiêu ngay'),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Watch Records
    final recordsState = ref.watch(recordsProvider(primaryGoal.id));
    final List<MonthlyRecord> records = recordsState.maybeWhen(
      data: (data) => data,
      orElse: () => [],
    );

    final now = DateTime.now();
    final thisMonthRecord = records.cast<MonthlyRecord?>().firstWhere(
          (r) =>
              r?.recordMonth.year == now.year &&
              r?.recordMonth.month == now.month,
          orElse: () => null,
        );

    // 5. Calculate scenario
    final monthlySaving =
        _customMonthlySaving ?? primaryGoal.monthlySaving;

    final input = ScenarioInput(
      currentSavings: primaryGoal.currentSavings,
      monthlySaving: monthlySaving,
      targetAmount: primaryGoal.targetAmount,
      inflationRate: 0.05,
      varianceBuffer: 0.15,
      monthsWithActualData: 0,
      averageVariance: 0.0,
    );

    final result = _engine.calculate(input);

    final isPremium = ref.watch(isPremiumUserProvider);

    // 5. Build UI
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _showSwitchGoalSheet(context, goalsState as GoalsLoaded, isPremium),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(primaryGoal.emoji ?? '🎯'),
                const Gap(AppSizes.sm),
                Text(primaryGoal.name),
                const Gap(AppSizes.xs),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
          if (!isPremium)
            TextButton.icon(
              icon: const Icon(Icons.diamond, color: AppColors.primary),
              label: const Text('Nâng cấp',
                  style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                context.go('/home/paywall');
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
              context.go(AppRoutes.profile);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimelineCard(result, primaryGoal.targetAmount),
            const Gap(AppSizes.xl),
            _buildReliabilityScore(result.planReliability),
            const Gap(AppSizes.xl),
            _buildMonthlySavingSlider(profile.disposableIncome, monthlySaving),
            const Gap(AppSizes.xxl),
            _buildActionButtons(context, thisMonthRecord),
            const Gap(AppSizes.xxl),
            _buildHistorySection(records),
            const Gap(AppSizes.xxl),
          ],
        ),
      ),
    );
  }

  void _showSwitchGoalSheet(BuildContext context, GoalsLoaded goalsState, bool isPremium) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Gap(AppSizes.md),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(AppSizes.lg),
              Text('Mục tiêu của bạn', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Gap(AppSizes.md),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: goalsState.goals.length,
                  itemBuilder: (context, index) {
                    final goal = goalsState.goals[index];
                    final isCurrent = goal.id == goalsState.primaryGoal?.id;
                    return ListTile(
                      leading: Text(goal.emoji ?? '🎯', style: const TextStyle(fontSize: 24)),
                      title: Text(goal.name, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                      trailing: isCurrent ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (!isCurrent) {
                          ref.read(goalsProvider.notifier).setPrimaryGoal(goal.id);
                        }
                      },
                    );
                  },
                ),
              ),
              const Divider(color: AppColors.borderDark),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                title: const Text('Tạo mục tiêu mới', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isPremium && goalsState.goals.isNotEmpty) {
                    // Limit free users to 1 goal
                    context.go('/home/paywall');
                  } else {
                    context.go('/home/goal-selection');
                  }
                },
              ),
              const Gap(AppSizes.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineCard(ScenarioResult result, int target) {
    // Determine the year/month based on expected months
    final now = DateTime.now();
    final expectedDate = DateTime(now.year, now.month + result.expectedMonths);
    final isReached = result.expectedMonths == 0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Text(
            isReached ? 'Mục tiêu đã hoàn thành! 🎉' : 'Dự kiến hoàn thành vào',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Gap(AppSizes.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isReached
                  ? 'Ngay bây giờ'
                  : 'Tháng ${expectedDate.month}/${expectedDate.year}',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(color: AppColors.primary),
              maxLines: 1,
            ),
          ),
          const Gap(AppSizes.lg),
          const Divider(),
          const Gap(AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCaseStat(
                  'Sớm nhất', result.bestCaseMonths, AppColors.success),
              _buildCaseStat(
                  'Chậm nhất', result.worstCaseMonths, AppColors.danger),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaseStat(String label, int months, Color color) {
    if (months == 0) return const SizedBox();

    final now = DateTime.now();
    final date = DateTime(now.year, now.month + months);

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Gap(4),
        Text(
          'T${date.month}/${date.year}',
          style:
              Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildReliabilityScore(double score) {
    Color getScoreColor(double score) {
      if (score >= 80) return AppColors.success;
      if (score >= 50) return AppColors.warning;
      return AppColors.danger;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Độ tin cậy của kế hoạch',
                style: Theme.of(context).textTheme.titleMedium),
            Text('${score.toInt()}%',
                style: TextStyle(
                    color: getScoreColor(score), fontWeight: FontWeight.bold)),
          ],
        ),
        const Gap(AppSizes.sm),
        LinearProgressIndicator(
          value: score / 100,
          backgroundColor: AppColors.surfaceElevatedDark,
          color: getScoreColor(score),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const Gap(AppSizes.xs),
        Text(
          'Dựa trên thông tin bạn cung cấp. Cập nhật thực tế hàng tháng để tăng độ tin cậy.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildMonthlySavingSlider(int maxDisposable, int currentSaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mức tiết kiệm mỗi tháng',
                style: Theme.of(context).textTheme.titleMedium),
            Text(CurrencyFormatter.format(currentSaving),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const Gap(AppSizes.md),
        Slider(
          value: currentSaving.toDouble(),
          min: 0,
          max: maxDisposable.toDouble(),
          divisions: 20,
          onChanged: (val) {
            setState(() {
              _customMonthlySaving = val.toInt();
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 ₫', style: Theme.of(context).textTheme.bodySmall),
            Text(CurrencyFormatter.format(maxDisposable),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, MonthlyRecord? thisMonthRecord) {
    return Column(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.help_outline),
          label: const Text('Thử kịch bản "What-if"?'),
          onPressed: () {
            context.go('/home/what-if');
          },
        ),
        const Gap(AppSizes.md),
        ElevatedButton.icon(
          icon: Icon(thisMonthRecord != null
              ? Icons.edit
              : Icons.check_circle_outline),
          label: Text(thisMonthRecord != null
              ? 'Sửa Check-in tháng này'
              : 'Check-in tháng này'),
          onPressed: () {
            context.go('/home/monthly-checkin', extra: thisMonthRecord);
          },
        ),
      ],
    );
  }

  Widget _buildHistorySection(List<MonthlyRecord> records) {
    if (records.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Lịch sử tích luỹ', style: Theme.of(context).textTheme.titleLarge),
        const Gap(AppSizes.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,
          separatorBuilder: (_, __) => const Gap(AppSizes.sm),
          itemBuilder: (context, index) {
            final record = records[index];
            final actual = record.actualSavings ?? 0;
            final isGood = actual >= record.plannedSavings;

            return InkWell(
              onTap: () => context.go('/home/monthly-checkin', extra: record),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedDark,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: isGood
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isGood ? Icons.trending_up : Icons.trending_down,
                        color: isGood ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const Gap(AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Tháng ${record.recordMonth.month}/${record.recordMonth.year}',
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                              'Mục tiêu: ${CurrencyFormatter.format(record.plannedSavings)}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(CurrencyFormatter.format(actual),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isGood
                                    ? AppColors.success
                                    : AppColors.textPrimary)),
                        Text(
                            '${(record.variancePercent * 100).toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
