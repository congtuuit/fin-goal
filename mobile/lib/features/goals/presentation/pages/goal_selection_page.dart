import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/goals/presentation/providers/goal_provider.dart';
import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';

class GoalSelectionPage extends ConsumerStatefulWidget {
  const GoalSelectionPage({super.key});

  @override
  ConsumerState<GoalSelectionPage> createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends ConsumerState<GoalSelectionPage> {
  GoalType? _selectedType;
  bool _isLoading = false;

  final _presets = [
    _GoalPreset(type: GoalType.emergencyFund, icon: '🛡️', title: 'Quỹ dự phòng', desc: 'An tâm tài chính trước rủi ro'),
    _GoalPreset(type: GoalType.car, icon: '🚗', title: 'Mua xe', desc: 'Chiếc xe mơ ước của bạn'),
    _GoalPreset(type: GoalType.house, icon: '🏠', title: 'Mua nhà', desc: 'An cư lạc nghiệp'),
    _GoalPreset(type: GoalType.wedding, icon: '💍', title: 'Đám cưới', desc: 'Cho ngày trọng đại'),
    _GoalPreset(type: GoalType.travel, icon: '✈️', title: 'Du lịch', desc: 'Khám phá thế giới'),
    _GoalPreset(type: GoalType.retirement, icon: '🏖️', title: 'Nghỉ hưu', desc: 'Tự do tài chính tuổi xế chiều'),
    _GoalPreset(type: GoalType.custom, icon: '🎯', title: 'Mục tiêu khác', desc: 'Tự định nghĩa mục tiêu'),
  ];

  void _onSelectPreset(_GoalPreset preset) {
    final goalsState = ref.read(goalsProvider);
    int currentActive = 0;
    if (goalsState is GoalsLoaded) {
      currentActive = goalsState.goals.where((g) => g.status != 'archived').length;
    }
    
    final canCreate = ref.read(canCreateNewGoalProvider(currentActive));
    if (!canCreate) {
      context.push('/home/paywall');
      return;
    }

    setState(() => _selectedType = preset.type);
    _showGoalConfigSheet(preset);
  }

  Future<void> _showGoalConfigSheet(_GoalPreset preset) async {
    final amountCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: preset.title);
    
    final profileState = ref.read(profileProvider);
    // ignore: invalid_use_of_visible_for_testing_member
    final defaultMonthlySaving = profileState is ProfileLoaded ? profileState.profile?.suggestedMonthlySaving ?? 0 : 0;
    
    final currentSavingsCtrl = TextEditingController();
    final monthlySavingCtrl = TextEditingController(
      text: defaultMonthlySaving > 0 ? CurrencyFormatter.formatInput(defaultMonthlySaving) : '',
    );
    final deadlineCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    // true = Mức tiết kiệm cố định, false = Thời hạn cố định
    bool isBudgetFixed = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: AppSizes.pageHorizontalPadding,
                right: AppSizes.pageHorizontalPadding,
                top: AppSizes.xl,
              ),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(preset.icon, style: const TextStyle(fontSize: 32)),
                          const Gap(AppSizes.sm),
                          Text('Cấu hình mục tiêu', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const Gap(AppSizes.xl),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Tên mục tiêu'),
                        validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const Gap(AppSizes.lg),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền mục tiêu',
                          hintText: 'VD: 50.000.000',
                          suffixText: '₫',
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Vui lòng nhập số tiền';
                          final val = CurrencyFormatter.parse(v);
                          if (val == null || val <= 0) return 'Số tiền không hợp lệ';
                          return null;
                        },
                        onChanged: (value) {
                          final parsed = CurrencyFormatter.parse(value);
                          if (parsed != null) {
                            final formatted = CurrencyFormatter.formatInput(parsed);
                            if (formatted != value) {
                              amountCtrl.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          }
                        },
                      ),
                      const Gap(AppSizes.lg),
                      TextFormField(
                        controller: currentSavingsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Số tiền đã có sẵn (Tùy chọn)',
                          hintText: 'VD: 10.000.000',
                          suffixText: '₫',
                        ),
                        onChanged: (value) {
                          final parsed = CurrencyFormatter.parse(value);
                          if (parsed != null) {
                            final formatted = CurrencyFormatter.formatInput(parsed);
                            if (formatted != value) {
                              currentSavingsCtrl.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          }
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
                              label: const Text('Ngân sách hàng tháng'),
                              selected: isBudgetFixed,
                              onSelected: (val) => setModalState(() => isBudgetFixed = true),
                            ),
                          ),
                          const Gap(AppSizes.sm),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Thời hạn hoàn thành'),
                              selected: !isBudgetFixed,
                              onSelected: (val) => setModalState(() => isBudgetFixed = false),
                            ),
                          ),
                        ],
                      ),
                      const Gap(AppSizes.lg),
                      if (isBudgetFixed)
                        TextFormField(
                          controller: monthlySavingCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Số tiền sẽ tiết kiệm mỗi tháng',
                            hintText: 'VD: 5.000.000',
                            suffixText: '₫',
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Vui lòng nhập số tiền';
                            final val = CurrencyFormatter.parse(v);
                            if (val == null || val <= 0) return 'Số tiền không hợp lệ';
                            return null;
                          },
                          onChanged: (value) {
                            final parsed = CurrencyFormatter.parse(value);
                            if (parsed != null) {
                              final formatted = CurrencyFormatter.formatInput(parsed);
                              if (formatted != value) {
                                monthlySavingCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                            }
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
                      const Gap(AppSizes.xxl),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState?.validate() ?? false) {
                            final targetAmt = CurrencyFormatter.parse(amountCtrl.text) ?? 0;
                            final currentSav = CurrencyFormatter.parse(currentSavingsCtrl.text) ?? 0;
                            int finalMonthlySaving = 0;
                            
                            if (isBudgetFixed) {
                              finalMonthlySaving = CurrencyFormatter.parse(monthlySavingCtrl.text) ?? 0;
                            } else {
                              final months = int.parse(deadlineCtrl.text);
                              final remaining = targetAmt - currentSav;
                              finalMonthlySaving = remaining > 0 ? (remaining / months).ceil() : 0;
                            }

                            Navigator.pop(context);
                            _createGoal(
                              name: nameCtrl.text.trim(),
                              amount: targetAmt,
                              currentSavings: currentSav,
                              monthlySaving: finalMonthlySaving,
                              preset: preset,
                            );
                          }
                        },
                        child: const Text('Bắt đầu mô phỏng'),
                      ),
                      const Gap(AppSizes.xl),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
    // Reset selection if dismissed without creating
    if (mounted && !_isLoading) {
      setState(() => _selectedType = null);
    }
  }

  Future<void> _createGoal({
    required String name,
    required int amount,
    required int currentSavings,
    required int monthlySaving,
    required _GoalPreset preset,
  }) async {
    setState(() => _isLoading = true);
    
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final goal = Goal(
      id: '', // Supabase gen
      userId: userId,
      type: preset.type,
      name: name,
      targetAmount: amount,
      currentSavings: currentSavings,
      monthlySaving: monthlySaving,
      emoji: preset.icon,
      isPrimary: true, // First goal is primary
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final error = await ref.read(goalsProvider.notifier).createGoal(goal);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
        );
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mục tiêu của bạn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
              children: [
                const Gap(AppSizes.sm),
                Text(
                  'Bạn muốn đạt được điều gì?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate().fadeIn().slideX(begin: -0.05),
                const Gap(AppSizes.sm),
                Text(
                  'Chọn một mục tiêu để AI giúp bạn lập kế hoạch.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                const Gap(AppSizes.xl),
                ..._presets.map((preset) {
                  final isSelected = _selectedType == preset.type;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: InkWell(
                      onTap: () => _onSelectPreset(preset),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceDark,
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.borderDark,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSizes.sm),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevatedDark,
                                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                              ),
                              child: Text(preset.icon, style: const TextStyle(fontSize: 24)),
                            ),
                            const Gap(AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(preset.title, style: Theme.of(context).textTheme.titleMedium),
                                  const Gap(4),
                                  Text(preset.desc, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isSelected ? AppColors.primary : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: Duration(milliseconds: 200 + (_presets.indexOf(preset) * 50))).slideY(begin: 0.1),
                  );
                }),
              ],
            ),
    );
  }
}

class _GoalPreset {
  final GoalType type;
  final String icon;
  final String title;
  final String desc;

  const _GoalPreset({
    required this.type,
    required this.icon,
    required this.title,
    required this.desc,
  });
}
