import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';

class FinancialReportDialog extends StatelessWidget {
  final GameState gs;

  const FinancialReportDialog({super.key, required this.gs});

  static void show(BuildContext context, GameState gs) {
    showDialog(
      context: context,
      builder: (_) => FinancialReportDialog(gs: gs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 Báo Cáo Tài Chính',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.borderDark),
            const Gap(AppSizes.sm),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (gs.assets.isEmpty && gs.liabilities.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
                        child: Center(
                          child: Text(
                            'Bạn chưa có tài sản hay khoản nợ nào.',
                            style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ),
                    // Assets
                    if (gs.assets.isNotEmpty) ...[
                      const Text('✅ Tài Sản',
                          style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                      const Gap(AppSizes.xs),
                      ...gs.assets.map(
                        (a) => _ReportRow(
                          label: a.name,
                          value: CurrencyFormatter.compact(a.currentValue),
                          sub: a.monthlyPassiveIncome > 0
                              ? '+${CurrencyFormatter.compact(a.monthlyPassiveIncome)}/tháng'
                              : null,
                          color: AppColors.success,
                        ),
                      ),
                      const Gap(AppSizes.md),
                    ],
                    // Liabilities
                    if (gs.liabilities.isNotEmpty) ...[
                      const Text('❌ Tiêu Sản & Nợ',
                          style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                      const Gap(AppSizes.xs),
                      ...gs.liabilities.map(
                        (l) => _ReportRow(
                          label: l.name,
                          value: CurrencyFormatter.compact(l.totalOwed),
                          sub: '-${CurrencyFormatter.compact(l.monthlyPayment)}/tháng',
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;

  const _ReportRow({
    required this.label,
    required this.value,
    this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                if (sub != null) Text(sub!, style: TextStyle(color: color, fontSize: 11)),
              ],
            ),
          ),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
