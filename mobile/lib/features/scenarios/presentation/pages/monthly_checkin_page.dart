import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../goals/presentation/providers/goal_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/entities/monthly_record.dart';
import '../providers/scenario_provider.dart';

class MonthlyCheckinPage extends ConsumerStatefulWidget {
  const MonthlyCheckinPage({super.key});

  @override
  ConsumerState<MonthlyCheckinPage> createState() => _MonthlyCheckinPageState();
}

class _MonthlyCheckinPageState extends ConsumerState<MonthlyCheckinPage> {
  final _formKey = GlobalKey<FormState>();
  final _actualCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _actualCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final profile = (ref.read(profileNotifierProvider) as ProfileLoaded).profile!;
    final goal = (ref.read(goalsNotifierProvider) as GoalsLoaded).primaryGoal!;
    
    final actual = CurrencyFormatter.parse(_actualCtrl.text) ?? 0;
    final planned = profile.suggestedMonthlySaving;
    
    // Calculate variance: (planned - actual) / planned
    final variance = planned > 0 ? (planned - actual) / planned : 0.0;
    
    // We just mock reliability here for MVP, the real logic should aggregate history
    final mockReliability = 50.0 + (variance < 0.1 ? 5.0 : -5.0);

    final record = MonthlyRecord(
      id: '',
      userId: profile.userId,
      goalId: goal.id,
      recordMonth: DateTime.now(),
      plannedSavings: planned,
      actualSavings: actual,
      variancePercent: variance,
      planReliability: mockReliability,
      createdAt: DateTime.now(),
    );

    // Save record
    final error = await ref.read(recordsNotifierProvider(goal.id).notifier).saveRecord(record);

    if (error == null) {
      // Update profile savings
      final updatedProfile = profile.copyWith(
        currentSavings: profile.currentSavings + actual,
      );
      await ref.read(profileNotifierProvider.notifier).updateProfile(updatedProfile);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Tháng'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
        child: _isSuccess ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildFormView() {
    final profileState = ref.watch(profileNotifierProvider);
    if (profileState is! ProfileLoaded || profileState.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final planned = profileState.profile!.suggestedMonthlySaving;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Gap(AppSizes.lg),
          Text(
            'Bạn đã tiết kiệm được bao nhiêu trong tháng này?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Gap(AppSizes.xl),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevatedDark,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mục tiêu tháng:'),
                Text(
                  CurrencyFormatter.format(planned),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const Gap(AppSizes.xl),
          TextFormField(
            controller: _actualCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: '0',
              suffixText: '₫',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Vui lòng nhập số tiền';
              if ((CurrencyFormatter.parse(v) ?? -1) < 0) return 'Số tiền không hợp lệ';
              return null;
            },
            onChanged: (value) {
              final parsed = CurrencyFormatter.parse(value);
              if (parsed != null) {
                final formatted = CurrencyFormatter.formatInput(parsed);
                if (formatted != value) {
                  _actualCtrl.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              }
            },
          ),
          const Gap(AppSizes.xxl),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Xác nhận'),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Gap(AppSizes.xxl),
        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 80)
            .animate()
            .scale(delay: 200.ms, curve: Curves.easeOutBack),
        const Gap(AppSizes.xl),
        Text(
          'Đã cập nhật thành công!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ).animate().fadeIn(delay: 400.ms),
        const Gap(AppSizes.md),
        Text(
          'Tổng tiết kiệm của bạn đã được cập nhật.\nĐộ tin cậy của kế hoạch đã tăng lên.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ).animate().fadeIn(delay: 600.ms),
        const Gap(AppSizes.xxl),
        ElevatedButton(
          onPressed: () => context.pop(),
          child: const Text('Quay lại Dashboard'),
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }
}
