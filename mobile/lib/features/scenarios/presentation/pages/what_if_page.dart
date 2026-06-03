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
import '../../domain/entities/scenario_query.dart';
import '../../engine/scenario_engine.dart';
import '../../engine/scenario_input.dart';
import '../providers/scenario_provider.dart';
import '../providers/ai_explanation_provider.dart';
import '../widgets/ai_explanation_card.dart';

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

    final profile = (ref.read(profileNotifierProvider) as ProfileLoaded).profile!;
    final goal = (ref.read(goalsNotifierProvider) as GoalsLoaded).primaryGoal!;
    
    final cost = CurrencyFormatter.parse(_costCtrl.text) ?? 0;
    
    final input = ScenarioInput(
      currentSavings: profile.currentSavings,
      monthlySaving: profile.suggestedMonthlySaving,
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

    ref.read(scenarioQueriesNotifierProvider(goal.id).notifier).saveQuery(query);
    ref.read(aiExplanationNotifierProvider.notifier).generateExplanationForWhatIf(query);

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
                    final explanationState = ref.watch(aiExplanationNotifierProvider);
                    return AiExplanationCard(
                      text: explanationState.valueOrNull,
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
