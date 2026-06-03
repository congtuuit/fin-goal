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
import 'package:fin_goal/features/scenarios/domain/entities/scenario_query.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_engine.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_input.dart';
import 'package:fin_goal/features/scenarios/presentation/providers/scenario_provider.dart';
import 'package:fin_goal/features/scenarios/presentation/providers/ai_explanation_provider.dart';
import 'package:fin_goal/features/scenarios/presentation/widgets/ai_explanation_card.dart';

class WhatIfPage extends ConsumerStatefulWidget {
  const WhatIfPage({super.key});

  @override
  ConsumerState<WhatIfPage> createState() => _WhatIfPageState();
}

class _WhatIfPageState extends ConsumerState<WhatIfPage> {
  final _engine = const ScenarioEngine();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  
  bool _isCalculated = false;
  int _delayMonths = 0;
  ScenarioQuery? _lastQuery;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  void _calculateImpact() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = (ref.read(profileProvider) as ProfileLoaded).profile!;
    final goal = (ref.read(goalsProvider) as GoalsLoaded).primaryGoal!;
    
    final cost = CurrencyFormatter.parse(_costCtrl.text) ?? 0;
    
    final input = ScenarioInput(
      currentSavings: goal.currentSavings,
      monthlySaving: goal.monthlySaving > 0 ? goal.monthlySaving : profile.suggestedMonthlySaving,
      targetAmount: goal.targetAmount,
      inflationRate: 0.05,
      varianceBuffer: 0.15,
      monthsWithActualData: 0,
      averageVariance: 0.0,
    );

    final delay = _engine.whatIfPurchaseImpact(input: input, purchaseCost: cost);

    final query = ScenarioQuery(
      id: '',
      userId: profile.userId,
      goalId: goal.id,
      itemName: _nameCtrl.text.trim(),
      itemCost: cost,
      impactMonths: delay.toDouble(),
      createdAt: DateTime.now(),
    );

    ref.read(scenarioQueriesProvider(goal.id).notifier).saveQuery(query);
    ref.read(aiExplanationProvider.notifier).generateExplanationForWhatIf(query);

    setState(() {
      _delayMonths = delay;
      _lastQuery = query;
      _isCalculated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kịch bản "What-if"'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Gap(AppSizes.lg),
              Text(
                'Nếu tôi mua...',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Gap(AppSizes.md),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên món đồ (VD: iPhone 15 Pro Max)',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Vui lòng nhập tên món đồ' : null,
              ),
              const Gap(AppSizes.md),
              TextFormField(
                controller: _costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá tiền',
                  suffixText: '₫',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập giá tiền';
                  if ((CurrencyFormatter.parse(v) ?? 0) <= 0) return 'Giá tiền không hợp lệ';
                  return null;
                },
                onChanged: (value) {
                  final parsed = CurrencyFormatter.parse(value);
                  if (parsed != null) {
                    final formatted = CurrencyFormatter.formatInput(parsed);
                    if (formatted != value) {
                      _costCtrl.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    }
                  }
                },
              ),
              const Gap(AppSizes.xl),
              ElevatedButton(
                onPressed: _calculateImpact,
                child: const Text('Xem tác động'),
              ),
              
              if (_isCalculated && _lastQuery != null) ...[
                const Gap(AppSizes.xxl),
                _buildResultCard(),
                const Gap(AppSizes.xl),
                Consumer(
                  builder: (context, ref, _) {
                    final explanationState = ref.watch(aiExplanationProvider);
                    
                    if (explanationState.hasError) {
                      final errorMsg = explanationState.error.toString();
                      final isKeyError = errorMsg.contains('API Key');
                      
                      return Container(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                                const Gap(AppSizes.sm),
                                Text(
                                  'Cấu hình AI chưa hoàn tất',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const Gap(AppSizes.md),
                            Text(errorMsg, style: Theme.of(context).textTheme.bodyMedium),
                            if (isKeyError) ...[
                              const Gap(AppSizes.md),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.settings, size: 16, color: Colors.white),
                                label: const Text('Đi tới Cài đặt', style: TextStyle(color: Colors.white)),
                                onPressed: () => context.go('/profile'),
                              ),
                            ]
                          ],
                        ),
                      ).animate().fadeIn();
                    }
                    
                    return AiExplanationCard(
                      text: explanationState.value,
                      isLoading: explanationState.isLoading,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 48),
          const Gap(AppSizes.md),
          Text(
            'Nếu mua ${_lastQuery!.itemName}, mục tiêu của bạn sẽ bị chậm lại:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Gap(AppSizes.lg),
          Text(
            '$_delayMonths tháng',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(AppSizes.lg),
          Text(
            'Dựa trên thông tin thu nhập và mức tiết kiệm hiện tại.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}
