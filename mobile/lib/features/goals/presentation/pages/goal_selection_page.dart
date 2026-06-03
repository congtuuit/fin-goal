import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/goal.dart';
import '../providers/goal_provider.dart';

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
    setState(() => _selectedType = preset.type);
    _showGoalConfigSheet(preset);
  }

  Future<void> _showGoalConfigSheet(_GoalPreset preset) async {
    final amountCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: preset.title);
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSizes.pageHorizontalPadding,
            right: AppSizes.pageHorizontalPadding,
            top: AppSizes.xl,
          ),
          child: Form(
            key: formKey,
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
                const Gap(AppSizes.xxl),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context);
                      _createGoal(
                        name: nameCtrl.text.trim(),
                        amount: CurrencyFormatter.parse(amountCtrl.text)!,
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
        context.go('/scenarios');
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
