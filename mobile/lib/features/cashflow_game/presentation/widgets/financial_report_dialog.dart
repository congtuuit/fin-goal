import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_goal/features/cashflow_game/presentation/providers/game_provider.dart';

class FinancialReportDialog extends ConsumerStatefulWidget {
  final GameState gs;

  const FinancialReportDialog({super.key, required this.gs});

  static void show(BuildContext context, GameState gs) {
    showDialog(
      context: context,
      builder: (_) => FinancialReportDialog(gs: gs),
    );
  }

  @override
  ConsumerState<FinancialReportDialog> createState() => _FinancialReportDialogState();
}

class _FinancialReportDialogState extends ConsumerState<FinancialReportDialog> {
  late ConfettiController _confettiController;
  final GlobalKey _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.gs.isFinanciallyFree) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _shareReport() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null) return;

      final directory = await getTemporaryDirectory();
      final imageFile = await File('${directory.path}/financial_report.png').create();
      await imageFile.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(imageFile.path)], text: 'Báo Cáo Tài Chính - Trò chơi Cashflow');
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _showPayDebtDialog(String liabilityId, int totalOwed, String name) async {
    final TextEditingController controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevatedDark,
        title: Text('Thanh toán nợ: $name', style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn đang nợ: ${CurrencyFormatter.compact(totalOwed)}', style: const TextStyle(color: Colors.white70)),
            Text('Tiền mặt hiện có: ${CurrencyFormatter.compact(widget.gs.cashOnHand)}', style: const TextStyle(color: AppColors.success)),
            const Gap(AppSizes.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền muốn trả (VND)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(controller.text.replaceAll(',', '')) ?? 0;
              if (amount > 0) {
                ref.read(cashflowGameProvider.notifier).payDebt(liabilityId, amount);
                Navigator.pop(ctx);
                Navigator.pop(context); // Đóng báo cáo tài chính
              }
            },
            child: const Text('Thanh toán'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return Dialog(
      backgroundColor: AppColors.surfaceElevatedDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 Báo Cáo Tài Chính',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.blueAccent),
                      tooltip: 'Chia Sẻ Kết Quả',
                      onPressed: _shareReport,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: AppColors.borderDark),
            const Gap(AppSizes.sm),
            Expanded(
              child: Stack(
                children: [
                  RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      color: AppColors.surfaceElevatedDark,
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
                                  onPay: () => _showPayDebtDialog(l.id, l.totalOwed, l.name),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        emissionFrequency: 0.05,
                        numberOfParticles: 20,
                        gravity: 0.1,
                      ),
                    ),
                  ),
                ],
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
  final VoidCallback? onPay;

  const _ReportRow({
    required this.label,
    required this.value,
    this.sub,
    required this.color,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              if (onPay != null) ...[
                const Gap(AppSizes.sm),
                SizedBox(
                  height: 24,
                  child: OutlinedButton(
                    onPressed: onPay,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: BorderSide(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text('Trả nợ', style: TextStyle(color: color, fontSize: 10)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
