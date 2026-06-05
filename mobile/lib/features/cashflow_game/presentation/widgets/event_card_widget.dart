import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/cashflow_game/engine/event_engine.dart';
import 'package:fin_goal/features/cashflow_game/presentation/providers/game_provider.dart';
import 'package:fin_goal/features/cashflow_game/presentation/widgets/financial_report_dialog.dart';

class EventCardWidget extends ConsumerWidget {
  final EventCard card;

  const EventCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        padding: const EdgeInsets.fromLTRB(
            AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevatedDark,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl)),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(AppSizes.md),
                
                // Scrollable content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card title
                        Padding(
                          padding: const EdgeInsets.only(right: 80.0), // make room for button
                          child: Text(
                            card.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.left,
                          ).animate().slideY(begin: 0.1).fadeIn(),
                        ),

                        const Gap(AppSizes.md),

                        // Description
                        Container(
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(color: AppColors.borderDark),
                          ),
                          child: Text(
                            card.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ).animate(delay: 100.ms).fadeIn(),
                      ],
                    ),
                  ),
                ),
                
                const Gap(AppSizes.lg),

                // Pinned Choices at bottom
                ...card.choices.asMap().entries.map((e) {
                  final idx = e.key;
                  final choice = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: _ChoiceButton(choice: choice, isPrimary: idx == 0),
                  )
                      .animate(
                          delay: Duration(milliseconds: 150 + idx * 80))
                      .fadeIn()
                      .slideY(begin: 0.05);
                }),
              ],
            ),

            // Pinned Xem báo cáo button at top right
            Positioned(
              top: 0,
              right: 0,
              child: OutlinedButton.icon(
                onPressed: () {
                  final state = ref.read(cashflowGameProvider);
                  if (state is GameUiPlaying) {
                    FinancialReportDialog.show(context, state.gameState);
                  }
                },
                icon: const Text('📊', style: TextStyle(fontSize: 12)),
                label: const Text('Báo cáo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.borderDark),
                  padding: const EdgeInsets.symmetric(
                      vertical: 2, horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ).animate(delay: 150.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends ConsumerWidget {
  final EventChoice choice;
  final bool isPrimary;

  const _ChoiceButton({required this.choice, required this.isPrimary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // close bottom sheet
        ref.read(cashflowGameProvider.notifier).applyChoice(choice);
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isPrimary
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.borderDark,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              choice.label,
              style: TextStyle(
                color: isPrimary ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const Gap(AppSizes.xs),
            Text(
              choice.shortDescription,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Gap(AppSizes.sm),
            // Teaching moment
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡 ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    choice.teachingMoment,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            // Impact chips
            const Gap(AppSizes.xs),
            _buildImpactChips(choice.impact),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactChips(EventImpact impact) {
    final chips = <Widget>[];

    if (impact.cashChange != 0) {
      final positive = impact.cashChange > 0;
      chips.add(_chip(
        '${positive ? '+' : ''}${CurrencyFormatter.compact(impact.cashChange)}',
        positive ? Colors.green : Colors.red,
      ));
    }
    if (impact.newAssetName != null) {
      chips.add(_chip('+ ${impact.newAssetName}', Colors.green));
    }
    if (impact.newAssetPassiveIncome != null &&
        impact.newAssetPassiveIncome! > 0) {
      chips.add(_chip(
        '+${CurrencyFormatter.compact(impact.newAssetPassiveIncome!)}/tháng',
        Colors.teal,
      ));
    }
    if (impact.newLiabilityName != null) {
      chips.add(_chip('+ Nợ mới', Colors.red));
    }
    if (impact.downsizeTurns > 0) {
      chips.add(_chip('Mất ${impact.downsizeTurns} lượt', Colors.orange));
    }
    if (impact.addChild) {
      chips.add(_chip('+ 1 Con', Colors.purple));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}
