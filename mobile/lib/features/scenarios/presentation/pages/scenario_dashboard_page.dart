import 'package:fin_goal/features/goals/domain/entities/goal.dart';
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
import 'package:fin_goal/features/coach/presentation/widgets/ai_coach_card.dart';

class ScenarioDashboardPage extends ConsumerStatefulWidget {
  const ScenarioDashboardPage({super.key});

  @override
  ConsumerState<ScenarioDashboardPage> createState() =>
      _ScenarioDashboardPageState();
}

class _ScenarioDashboardPageState extends ConsumerState<ScenarioDashboardPage> {
  final _engine = const ScenarioEngine();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _targetAmountController;
  late TextEditingController _currentSavingsController;
  late TextEditingController _monthlySavingController;

  // Local state for the slider
  int? _customMonthlySaving;

  // Macro What-if state
  double _customInflationRate = 0.05;
  double _customInvestmentReturn = 0.0;
  double _customIncomeGrowth = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _targetAmountController = TextEditingController();
    _currentSavingsController = TextEditingController();
    _monthlySavingController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentSavingsController.dispose();
    _monthlySavingController.dispose();
    super.dispose();
  }

  void _showEditDialog(Goal goal) {
    _nameController.text = goal.name;
    _targetAmountController.text = CurrencyFormatter.formatInput(goal.targetAmount);
    _currentSavingsController.text = CurrencyFormatter.formatInput(goal.currentSavings);
    _monthlySavingController.text = CurrencyFormatter.formatInput(goal.monthlySaving);
    
    final deadlineCtrl = TextEditingController();
    bool isBudgetFixed = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceDark,
              title: const Text('Chỉnh sửa mục tiêu'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên mục tiêu',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Vui lòng nhập tên';
                          return null;
                        },
                      ),
                      const Gap(AppSizes.md),
                      TextFormField(
                        controller: _targetAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền mục tiêu',
                          suffixText: '₫',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final parsed = CurrencyFormatter.parse(value);
                          if (parsed != null) {
                            final formatted = CurrencyFormatter.formatInput(parsed);
                            if (formatted != value) {
                              _targetAmountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền';
                          if (CurrencyFormatter.parse(value) == null) return 'Số tiền không hợp lệ';
                          return null;
                        },
                      ),
                      const Gap(AppSizes.md),
                      TextFormField(
                        controller: _currentSavingsController,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền đã có',
                          suffixText: '₫',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final parsed = CurrencyFormatter.parse(value);
                          if (parsed != null) {
                            final formatted = CurrencyFormatter.formatInput(parsed);
                            if (formatted != value) {
                              _currentSavingsController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          }
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền';
                          if (CurrencyFormatter.parse(value) == null) return 'Số tiền không hợp lệ';
                          return null;
                        },
                      ),
                      const Gap(AppSizes.xl),
                      Text(
                        'Điều gì là cố định đối với bạn?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Gap(AppSizes.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Mức tiết kiệm'),
                              selected: isBudgetFixed,
                              onSelected: (val) => setModalState(() => isBudgetFixed = true),
                            ),
                          ),
                          const Gap(AppSizes.sm),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Thời hạn'),
                              selected: !isBudgetFixed,
                              onSelected: (val) => setModalState(() => isBudgetFixed = false),
                            ),
                          ),
                        ],
                      ),
                      const Gap(AppSizes.md),
                      if (isBudgetFixed)
                        TextFormField(
                          controller: _monthlySavingController,
                          decoration: const InputDecoration(
                            labelText: 'Mức tiết kiệm mỗi tháng',
                            suffixText: '₫',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final parsed = CurrencyFormatter.parse(value);
                            if (parsed != null) {
                              final formatted = CurrencyFormatter.formatInput(parsed);
                              if (formatted != value) {
                                _monthlySavingController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            }
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Vui lòng nhập số tiền';
                            if (CurrencyFormatter.parse(value) == null) return 'Số tiền không hợp lệ';
                            return null;
                          },
                        )
                      else
                        TextFormField(
                          controller: deadlineCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số tháng mong muốn hoàn thành',
                            hintText: 'VD: 24',
                            suffixText: 'tháng',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Vui lòng nhập số tháng';
                            final val = int.tryParse(v);
                            if (val == null || val <= 0) return 'Số tháng không hợp lệ';
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final targetAmt = CurrencyFormatter.parse(_targetAmountController.text.trim()) ?? goal.targetAmount;
                      final currentSav = CurrencyFormatter.parse(_currentSavingsController.text.trim()) ?? goal.currentSavings;
                      int finalMonthlySaving = 0;
                      
                      if (isBudgetFixed) {
                        finalMonthlySaving = CurrencyFormatter.parse(_monthlySavingController.text.trim()) ?? goal.monthlySaving;
                      } else {
                        final months = int.parse(deadlineCtrl.text);
                        final remaining = targetAmt - currentSav;
                        finalMonthlySaving = remaining > 0 ? (remaining / months).ceil() : 0;
                      }

                      final updatedGoal = goal.copyWith(
                        name: _nameController.text.trim(),
                        targetAmount: targetAmt,
                        currentSavings: currentSav,
                        monthlySaving: finalMonthlySaving,
                        updatedAt: DateTime.now(),
                      );
                      ref.read(goalsProvider.notifier).updateGoal(updatedGoal);

                      // Reset custom saving if it was set
                      if (_customMonthlySaving != null) {
                        setState(() {
                          _customMonthlySaving = null;
                        });
                      }

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã cập nhật mục tiêu thành công!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

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
              onPressed: () => context.push(AppRoutes.profile),
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
                onPressed: () => context.push('/home/goal-selection'),
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
    final monthlySaving = _customMonthlySaving ?? primaryGoal.monthlySaving;

    final input = ScenarioInput(
      currentSavings: primaryGoal.currentSavings,
      monthlySaving: monthlySaving,
      targetAmount: primaryGoal.targetAmount,
      inflationRate: _customInflationRate,
      investmentReturn: _customInvestmentReturn,
      incomeGrowth: _customIncomeGrowth,
      varianceBuffer: 0.15,
      monthsWithActualData: 0,
      averageVariance: 0.0,
    );

    final result = _engine.calculate(input);

    final isPremium = ref.watch(isPremiumUserProvider);

    // 5. Build UI
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _showSwitchGoalSheet(context, goalsState, isPremium),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(primaryGoal.emoji ?? '🎯'),
                const Gap(AppSizes.xs),
                Flexible(
                  child: Text(
                    primaryGoal.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(primaryGoal),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push(AppRoutes.profile);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  primaryGoal.emoji ?? '🎯',
                  style: const TextStyle(fontSize: 32),
                ),
                const Gap(AppSizes.md),
                Expanded(
                  child: Text(
                    primaryGoal.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const Gap(AppSizes.md),
            _buildTimelineCard(result, primaryGoal.targetAmount),
            const Gap(AppSizes.md),
            // ── AI Financial Coach Card ───────────────────────────────────
            AiCoachCard(goal: primaryGoal),
            const Gap(AppSizes.md),
            _buildMacroControlPanel(isPremium),
            const Gap(AppSizes.md),
            _buildReliabilityScore(result.planReliability),
            const Gap(AppSizes.md),
            _buildMonthlySavingSlider(profile.disposableIncome, monthlySaving),
            const Gap(AppSizes.lg),
            _buildActionButtons(context, thisMonthRecord),
            const Gap(AppSizes.lg),
            _buildHistorySection(records),
            const Gap(AppSizes.xl),
          ],
        ),
      ),
    );
  }

  void _showSwitchGoalSheet(
      BuildContext context, GoalsLoaded goalsState, bool isPremium) {
    final activeGoals = goalsState.goals.where((g) => g.status != 'archived').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SafeArea(
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
                  Text('Mục tiêu của bạn',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Gap(AppSizes.md),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: activeGoals.length,
                      itemBuilder: (context, index) {
                        final goal = activeGoals[index];
                        final isCurrent = goal.id == goalsState.primaryGoal?.id;
                        return ListTile(
                          leading: Text(goal.emoji ?? '🎯',
                              style: const TextStyle(fontSize: 24)),
                          title: Text(goal.name,
                              style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle,
                                  color: AppColors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(ctx);
                            if (!isCurrent) {
                              ref
                                  .read(goalsProvider.notifier)
                                  .setPrimaryGoal(goal.id);
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(color: AppColors.borderDark),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline,
                        color: AppColors.primary, size: 28),
                    title: const Text('Tạo mục tiêu mới',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(ctx);
                      final canCreate = ref.read(canCreateNewGoalProvider(activeGoals.length));
                      if (!canCreate) {
                        context.push('/home/paywall');
                      } else {
                        context.push('/home/goal-selection');
                      }
                    },
                  ),
                  const Gap(AppSizes.md),
                ],
              ),
            ));
      },
    );
  }

  Widget _buildTimelineCard(ScenarioResult result, int target) {
    final now = DateTime.now();
    final expectedDate = DateTime(now.year, now.month + result.expectedMonths);
    final isReached = result.expectedMonths == 0;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isReached ? 'Đã hoàn thành! 🎉' : 'Dự kiến hoàn thành',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Gap(AppSizes.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isReached
                          ? 'Ngay bây giờ'
                          : '${expectedDate.month}/${expectedDate.year}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            if (!isReached) ...[
              const Gap(AppSizes.sm),
              const VerticalDivider(width: 1, color: AppColors.borderDark),
              const Gap(AppSizes.md),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCompactCaseStat('Sớm nhất', result.bestCaseMonths, AppColors.success),
                    const Gap(AppSizes.sm),
                    _buildCompactCaseStat('Chậm nhất', result.worstCaseMonths, AppColors.danger),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCaseStat(String label, int months, Color color) {
    if (months <= 0) return const SizedBox();

    final now = DateTime.now();
    final date = DateTime(now.year, now.month + months);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Gap(2),
        Text(
          'T${date.month}/${date.year}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color, 
            fontWeight: FontWeight.bold
          ),
        ),
      ],
    );
  }

  Widget _buildMacroControlPanel(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AppColors.primary),
              const Gap(AppSizes.sm),
              Text('Kịch bản Vĩ mô (Macro)', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
            ],
          ),
          const Gap(AppSizes.md),
          _buildMacroSlider(
            label: 'Lạm phát',
            value: _customInflationRate,
            min: 0.0,
            max: 0.15,
            onChanged: (val) => setState(() => _customInflationRate = val),
          ),
          const Gap(AppSizes.sm),
          _buildMacroSlider(
            label: 'Lãi suất đầu tư',
            value: _customInvestmentReturn,
            min: 0.0,
            max: 0.20,
            onChanged: (val) => setState(() => _customInvestmentReturn = val),
          ),
          const Gap(AppSizes.sm),
          _buildMacroSlider(
            label: 'Tăng thu nhập/năm',
            value: _customIncomeGrowth,
            min: 0.0,
            max: 0.10,
            onChanged: (val) => setState(() => _customIncomeGrowth = val),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text('${(value * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            thumbColor: AppColors.primary,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            onChanged: onChanged,
          ),
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
            context.push('/home/what-if');
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
            context.push('/home/monthly-checkin', extra: thisMonthRecord);
          },
        ),
      ],
    );
  }

  Widget _buildHistorySection(List<MonthlyRecord> records) {
    if (records.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Lịch sử tích luỹ', style: Theme.of(context).textTheme.titleLarge),
          const Gap(AppSizes.md),
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl, horizontal: AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: Column(
              children: [
                const Icon(Icons.history_toggle_off, size: 64, color: AppColors.textMuted),
                const Gap(AppSizes.md),
                Text(
                  'Chưa có dữ liệu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(AppSizes.sm),
                Text(
                  'Hãy cập nhật tiến độ mỗi tháng để AI theo dõi sát sao mục tiêu của bạn.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

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
              onTap: () => context.push('/home/monthly-checkin', extra: record),
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
                            : AppColors.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isGood ? Icons.trending_up : Icons.trending_down,
                        color: isGood ? AppColors.success : AppColors.danger,
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
