import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/goals/presentation/providers/goal_provider.dart';
import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_engine.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_input.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_result.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';
import 'package:fin_goal/app/router/routes.dart';

class ScenarioDashboardPage extends ConsumerStatefulWidget {
  const ScenarioDashboardPage({super.key});

  @override
  ConsumerState<ScenarioDashboardPage> createState() => _ScenarioDashboardPageState();
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
      return Scaffold(body: Center(child: Text('Lỗi: ${profileState.message}')));
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

    // 4. Calculate scenario
    final monthlySaving = _customMonthlySaving ?? profile.suggestedMonthlySaving;
    
    final input = ScenarioInput(
      currentSavings: profile.currentSavings,
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(primaryGoal.emoji ?? '🎯'),
            const Gap(AppSizes.sm),
            Text(primaryGoal.name),
          ],
        ),
        actions: [
          if (!isPremium)
            TextButton.icon(
              icon: const Icon(Icons.diamond, color: AppColors.primary),
              label: const Text('Nâng cấp', style: TextStyle(color: AppColors.primary)),
              onPressed: () {
                context.go('/home/paywall');
              },
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: Text('PRO', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
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
            _buildActionButtons(context),
            const Gap(AppSizes.xxl),
          ],
        ),
      ),
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
          Text(
            isReached ? 'Ngay bây giờ' : 'Tháng ${expectedDate.month}/${expectedDate.year}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: AppColors.primary),
          ),
          const Gap(AppSizes.lg),
          const Divider(),
          const Gap(AppSizes.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCaseStat('Sớm nhất', result.bestCaseMonths, AppColors.success),
              _buildCaseStat('Chậm nhất', result.worstCaseMonths, AppColors.danger),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
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
            Text('Độ tin cậy của kế hoạch', style: Theme.of(context).textTheme.titleMedium),
            Text('${score.toInt()}%', style: TextStyle(color: getScoreColor(score), fontWeight: FontWeight.bold)),
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
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildMonthlySavingSlider(int maxDisposable, int currentSaving) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mức tiết kiệm mỗi tháng', style: Theme.of(context).textTheme.titleMedium),
            Text(CurrencyFormatter.format(currentSaving), style: const TextStyle(fontWeight: FontWeight.bold)),
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
            Text(CurrencyFormatter.format(maxDisposable), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.help_outline),
          label: const Text('Thử kịch bản "What-if"?'),
          onPressed: () {
            context.go('/home/what-if');
          },
        ).animate().fadeIn(delay: 300.ms),
        const Gap(AppSizes.md),
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Check-in tháng này'),
          onPressed: () {
            context.go('/home/monthly-checkin');
          },
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}
