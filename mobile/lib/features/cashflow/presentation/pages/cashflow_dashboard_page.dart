import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/cashflow/presentation/providers/cashflow_provider.dart';

class CashflowDashboardPage extends ConsumerWidget {
  const CashflowDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cashflowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo "Cha Giàu"'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Chơi lại từ đầu',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Chơi lại?'),
                  content: const Text('Bạn có chắc muốn bắt đầu lại cuộc đời tài chính không?'),
                  actions: [
                    TextButton(onPressed: () => ctx.pop(), child: const Text('Hủy')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () {
                        ref.read(cashflowProvider.notifier).resetGame();
                        ctx.pop();
                      },
                      child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: _buildBody(context, state),
      floatingActionButton: state is CashflowGameReady
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/cashflow-game'),
              icon: const Icon(Icons.play_arrow),
              label: Text('Tháng ${state.state.currentMonth}: Chơi tiếp'),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, CashflowGameState state) {
    if (state is CashflowGameLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is CashflowGameError) {
      return Center(child: Text('Lỗi: ${state.message}'));
    } else if (state is CashflowGameReady) {
      final cashflow = state.state;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.pageHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFreedomMeter(context, cashflow.financialFreedomProgress),
            const Gap(AppSizes.xl),
            Row(
              children: [
                Expanded(child: _buildInfoCard('Tiền mặt', cashflow.cashOnHand, AppColors.success)),
                const Gap(AppSizes.md),
                Expanded(child: _buildInfoCard('Dòng tiền / Tháng', cashflow.monthlyCashflow, AppColors.primary)),
              ],
            ),
            const Gap(AppSizes.xl),
            
            // INCOME STATEMENT
            Text('BÁO CÁO THU NHẬP', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Gap(AppSizes.sm),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevatedDark,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                children: [
                  _buildRow('Lương (Chủ động)', cashflow.activeIncome, AppColors.success),
                  _buildRow('Thu nhập thụ động', cashflow.passiveIncome, AppColors.success),
                  const Divider(color: AppColors.borderDark),
                  _buildRow('Chi phí sinh hoạt', -cashflow.baseExpenses, AppColors.danger),
                  _buildRow('Trả nợ (Liabilities)', -(cashflow.totalExpenses - cashflow.baseExpenses), AppColors.danger),
                ],
              ),
            ),
            const Gap(AppSizes.xl),

            // BALANCE SHEET
            Text('BẢNG CÂN ĐỐI KẾ TOÁN', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey)),
            const Gap(AppSizes.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assets
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TÀI SẢN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                        const Gap(AppSizes.sm),
                        if (cashflow.assets.isEmpty)
                          const Text('Chưa có', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                        else
                          ...cashflow.assets.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text('• ${a.name}\n  +${CurrencyFormatter.format(a.passiveIncome)}/tháng', style: const TextStyle(fontSize: 12)),
                          )),
                      ],
                    ),
                  ),
                ),
                const Gap(AppSizes.md),
                // Liabilities
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevatedDark,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TIÊU SẢN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                        const Gap(AppSizes.sm),
                        if (cashflow.liabilities.isEmpty)
                          const Text('Chưa có', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                        else
                          ...cashflow.liabilities.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text('• ${l.name}\n  -${CurrencyFormatter.format(l.monthlyPayment)}/tháng', style: const TextStyle(fontSize: 12)),
                          )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Gap(100), // Space for FAB
          ],
        ),
      ).animate().fadeIn();
    }
    return const SizedBox.shrink();
  }

  Widget _buildFreedomMeter(BuildContext context, double progress) {
    return Column(
      children: [
        Text(
          'Rat Race Escape',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Gap(AppSizes.sm),
        LinearProgressIndicator(
          value: progress,
          minHeight: 20,
          backgroundColor: AppColors.surfaceElevatedDark,
          color: progress >= 1.0 ? AppColors.success : AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        const Gap(AppSizes.xs),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% (Thu nhập thụ động / Tổng chi phí)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedDark,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const Gap(AppSizes.xs),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, int amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
