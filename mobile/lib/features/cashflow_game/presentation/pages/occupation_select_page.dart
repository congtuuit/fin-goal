import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/occupation.dart';
import 'package:fin_goal/features/cashflow_game/data/datasources/occupations_data.dart';
import 'package:fin_goal/features/cashflow_game/presentation/providers/game_provider.dart';

class OccupationSelectPage extends ConsumerWidget {
  const OccupationSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text('Chọn Nghề Nghiệp'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.backgroundDark,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '🎮 Bắt Đầu Hành Trình',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Gap(AppSizes.sm),
                Text(
                  'Chọn nghề nghiệp để bắt đầu cuộc hành trình\nthoát khỏi Rat Race và đạt Tự Do Tài Chính!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // Occupation Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: AppSizes.md,
                mainAxisSpacing: AppSizes.md,
              ),
              itemCount: occupations.length,
              itemBuilder: (context, index) {
                final occ = occupations[index];
                return _OccupationCard(occupation: occ, index: index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupationCard extends ConsumerWidget {
  final Occupation occupation;
  final int index;

  const _OccupationCard({required this.occupation, required this.index});

  Color _difficultyColor() {
    return switch (occupation.difficulty) {
      'easy' => Colors.green,
      'medium' => Colors.amber,
      'hard' => Colors.orange,
      'expert' => Colors.red,
      _ => Colors.grey,
    };
  }

  String _difficultyLabel() {
    return switch (occupation.difficulty) {
      'easy' => 'Dễ',
      'medium' => 'Trung Bình',
      'hard' => 'Khó',
      'expert' => 'Chuyên Gia',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashflow = occupation.initialMonthlyCashflow;
    final cashflowColor =
        cashflow >= 0 ? AppColors.success : AppColors.danger;

    return GestureDetector(
      onTap: () => _onSelect(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevatedDark,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji + Difficulty badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(occupation.emoji,
                        style: const TextStyle(fontSize: 26)),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _difficultyColor().withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _difficultyColor().withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _difficultyLabel(),
                          style: TextStyle(
                              color: _difficultyColor(),
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Name
                Text(
                  occupation.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.2),
                ),
                const SizedBox(height: 4),

                // Stats
                _StatRow(
                  label: 'Lương',
                  value: CurrencyFormatter.compact(occupation.monthlySalary),
                  valueColor: AppColors.success,
                ),
                _StatRow(
                  label: 'Chi phí',
                  value: CurrencyFormatter.compact(
                      occupation.totalMonthlyExpenses),
                  valueColor: AppColors.danger,
                ),
                _StatRow(
                  label: 'Dòng Tiền',
                  value: CurrencyFormatter.compact(cashflow.abs()),
                  valueColor: cashflowColor,
                  prefix: cashflow >= 0 ? '+' : '-',
                ),

                const SizedBox(height: 4),

                // Stars
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < occupation.difficultyStars
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 11,
                      color: i < occupation.difficultyStars
                          ? Colors.amber
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: index * 50))
          .fadeIn()
          .slideY(begin: 0.1),
    );
  }

  void _onSelect(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevatedDark,
        title: Text('${occupation.emoji} ${occupation.name}'),
        content: Text(
          occupation.description,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(cashflowGameProvider.notifier)
                  .startGame(occupation);
              context.pop(); // về lại trang trước
            },
            child: const Text('Bắt Đầu!'),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String prefix;

  const _StatRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(
            '$prefix$value',
            style: TextStyle(
                color: valueColor,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
