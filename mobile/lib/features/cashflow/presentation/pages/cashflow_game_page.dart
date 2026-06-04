import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/cashflow/domain/entities/game_scenario.dart';
import 'package:fin_goal/features/cashflow/presentation/providers/cashflow_provider.dart';
import 'package:fin_goal/features/cashflow/presentation/widgets/rat_race_board_widget.dart';

class CashflowGamePage extends ConsumerStatefulWidget {
  const CashflowGamePage({super.key});

  @override
  ConsumerState<CashflowGamePage> createState() => _CashflowGamePageState();
}

class _CashflowGamePageState extends ConsumerState<CashflowGamePage> {
  GameOption? _selectedOption;

  @override
  void initState() {
    super.initState();
    // Khởi tạo không cần tự động tung xúc xắc
  }

  void _onOptionSelected(GameOption option) {
    setState(() => _selectedOption = option);
    
    // Hiện popup giải thích AI, sau đó apply và quay về dashboard
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: SingleChildScrollView(
          child: _buildAiFeedback(ctx, option),
        ),
      ),
    );
  }

  Widget _buildAiFeedback(BuildContext ctx, GameOption option) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.primary, size: 32),
              const Gap(AppSizes.sm),
              Text(
                'AI "Cha Giàu" Đánh Giá',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Gap(AppSizes.md),
          Text(
            option.aiFeedback,
            style: Theme.of(ctx).textTheme.bodyLarge,
          ),
          const Gap(AppSizes.xl),
          ElevatedButton(
            onPressed: () {
              ctx.pop(); // close bottom sheet
              ref.read(cashflowProvider.notifier).applyOption(option);
              context.pop(); // go back to dashboard
            },
            child: const Text('Tiếp tục (Qua tháng mới)'),
          ),
          const Gap(AppSizes.md),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashflowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thử Thách Tài Chính'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, CashflowGameState state) {
    if (state is! CashflowGameReady) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isGeneratingScenario) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const Gap(AppSizes.md),
            const Text('Đang tung xúc xắc & tính toán...').animate().fadeIn().shimmer(),
          ],
        ),
      );
    }

    final scenario = state.currentScenario;
    if (scenario == null) {
      return _buildBoardView(context, state);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SCENARIO CARD
          Container(
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  scenario.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Gap(AppSizes.md),
                Text(
                  scenario.description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),

          const Gap(AppSizes.xxl),
          Text(
            'Quyết định của bạn?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ).animate().fadeIn(delay: 200.ms),
          const Gap(AppSizes.md),

          // OPTIONS
          ...scenario.options.asMap().entries.map((e) {
            final idx = e.key;
            final opt = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: _buildOptionCard(opt),
            ).animate().slideX(begin: 0.1, delay: Duration(milliseconds: 300 + idx * 100)).fadeIn();
          }),
        ],
      ),
    );
  }

  Widget _buildBoardView(BuildContext context, CashflowGameReady state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tháng thứ \${state.state.currentMonth}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Gap(AppSizes.sm),
          Text(
            'Tiền mặt: \${CurrencyFormatter.format(state.state.cashOnHand)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.success),
          ),
          const Gap(AppSizes.xxl),
          
          // Vẽ vòng tròn đại diện Rat Race
          RatRaceBoardWidget(
            currentPosition: state.state.boardPosition,
            size: MediaQuery.of(context).size.width - 40,
          ),

          const Gap(AppSizes.xxl),
          if (state.state.downsizeTurns > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.md),
              child: Text(
                'Bạn đang bị thất nghiệp (Còn \${state.state.downsizeTurns} lượt)',
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
              ),
            ),

          SizedBox(
            width: 200,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
              ),
              onPressed: () => ref.read(cashflowProvider.notifier).rollDiceAndMove(),
              child: const Text('TUNG XÚC XẮC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ).animate().slideY(begin: 0.5).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildOptionCard(GameOption option) {
    return InkWell(
      onTap: () => _onOptionSelected(option),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Gap(AppSizes.xs),
            Text(
              option.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const Gap(AppSizes.sm),
            _buildImpactSummary(option.impact),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactSummary(GameImpact impact) {
    List<Widget> chips = [];
    
    if (impact.cashChange != 0) {
      chips.add(_impactChip(
        'Tiền: ${impact.cashChange > 0 ? '+' : ''}${CurrencyFormatter.format(impact.cashChange)}',
        impact.cashChange > 0 ? AppColors.success : AppColors.danger,
      ));
    }
    
    if (impact.addedAssets != null && impact.addedAssets!.isNotEmpty) {
      chips.add(_impactChip('+ Tài sản mới', AppColors.success));
    }
    
    if (impact.addedLiabilities != null && impact.addedLiabilities!.isNotEmpty) {
      chips.add(_impactChip('+ Nợ mới', AppColors.danger));
    }

    if (chips.isEmpty) {
      chips.add(_impactChip('Không ảnh hưởng', Colors.grey));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _impactChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
