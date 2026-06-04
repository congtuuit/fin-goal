import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fin_goal/core/constants/app_colors.dart';
import 'package:fin_goal/core/constants/app_sizes.dart';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';
import 'package:fin_goal/features/cashflow_game/engine/economy_engine.dart';
import 'package:fin_goal/features/cashflow_game/presentation/providers/game_provider.dart';
import 'package:fin_goal/features/cashflow_game/presentation/widgets/dice_widget.dart';
import 'package:fin_goal/features/cashflow_game/presentation/widgets/event_card_widget.dart';
import 'package:fin_goal/features/cashflow_game/presentation/widgets/rat_race_board_widget.dart';
import 'package:fin_goal/features/cashflow_game/presentation/widgets/financial_report_dialog.dart';
import 'package:fin_goal/features/cashflow_game/presentation/widgets/game_guide_dialog.dart';
import 'package:fin_goal/features/cashflow_game/presentation/pages/occupation_select_page.dart';
import 'package:fin_goal/features/cashflow_game/engine/board_engine.dart';
import 'package:fin_goal/core/utils/audio_player_manager.dart';

class BoardGamePage extends ConsumerStatefulWidget {
  const BoardGamePage({super.key});

  @override
  ConsumerState<BoardGamePage> createState() => _BoardGamePageState();
}

class _BoardGamePageState extends ConsumerState<BoardGamePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final s = ref.read(cashflowGameProvider);
      if (s is GameUiSelectOccupation) {
        _showOccupationSelect();
      }
    });
  }

  void _showOccupationSelect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OccupationSelectPage(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showEventCard(GameUiPlaying state) {
    if (state.currentEvent == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => EventCardWidget(card: state.currentEvent!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(cashflowGameProvider);

    // React to event card appearance
    ref.listen<CashflowGameUiState>(cashflowGameProvider, (prev, next) {
      if (next is GameUiPlaying && next.currentEvent != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showEventCard(next);
        });
      }
      if (next is GameUiFinanciallyFree) {
        _showWinDialog(next.gameState);
      }
      if (next is GameUiBankrupt) {
        _showLoseDialog(next.gameState);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(uiState),
      body: _buildBody(uiState),
    );
  }

  PreferredSizeWidget _buildAppBar(CashflowGameUiState s) {
    String title = 'Cashflow Board Game';
    if (s is GameUiPlaying) {
      title = '${s.gameState.occupation.emoji} ${s.gameState.occupation.name}';
    }
    return AppBar(
      title: Text(title),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (s is GameUiPlaying) ...[
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Hướng Dẫn & Thuật Ngữ',
            onPressed: () => GameGuideDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Báo Cáo Tài Chính',
            onPressed: () => FinancialReportDialog.show(context, s.gameState),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Chơi Lại',
            onPressed: () => _confirmReset(),
          ),
        ],
      ],
    );
  }

  Widget _buildBody(CashflowGameUiState s) {
    return switch (s) {
      GameUiLoading() => const Center(child: CircularProgressIndicator()),
      GameUiSelectOccupation() => _buildSelectPrompt(),
      GameUiPlaying() => _buildGame(s),
      GameUiFinanciallyFree() => const SizedBox.shrink(),
      GameUiBankrupt() => const SizedBox.shrink(),
      GameUiError() => Center(child: Text(s.message)),
    };
  }

  Widget _buildSelectPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎮', style: TextStyle(fontSize: 80)),
          const Gap(AppSizes.lg),
          const Text(
            'Chọn Nghề Nghiệp\nĐể Bắt Đầu!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Gap(AppSizes.xl),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: _showOccupationSelect,
              child: const Text('Chọn Nghề'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGame(GameUiPlaying state) {
    final gs = state.gameState;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // ── HUD Tài Chính (Cố định ở trên) ──────────────────────────────────────────────────
        _buildHud(gs, state),

        // ── Phần còn lại có thể cuộn ────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Gap(AppSizes.md),

                // ── Bàn Cờ ────────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RatRaceBoardWidget(
                    currentPosition: gs.boardPosition,
                    size: screenWidth - 32,
                  ),
                ),

                const Gap(AppSizes.md),

                // ── Thông tin Ô Hiện Tại ──────────────────────────────────────────
                _buildCurrentSpaceInfo(gs),

                const Gap(AppSizes.lg),

                // ── Xúc Xắc & Nút Tung ───────────────────────────────────────────
                _buildDiceSection(state),

                const Gap(AppSizes.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHud(GameState gs, GameUiPlaying state) {
    final progress = gs.financialFreedomProgress;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.backgroundDark,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Economy state & turn
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lượt ${gs.currentTurn}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  EconomyEngine.getStateName(gs.economyState),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ),
              Text(
                'Level ${gs.level} • ${gs.xp} XP',
                style:
                    const TextStyle(color: Colors.amber, fontSize: 12),
              ),
            ],
          ),

          const Gap(AppSizes.md),

          // Main stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HudStat(
                label: '💰 Tiền Mặt',
                value: CurrencyFormatter.compact(gs.cashOnHand),
                color: Colors.white,
              ),
              _HudStat(
                label: '📈 Thu Thụ Động',
                value: CurrencyFormatter.compact(gs.passiveIncome),
                color: AppColors.success,
              ),
              _HudStat(
                label: '💵 Dòng Tiền',
                value: CurrencyFormatter.compact(gs.monthlyCashflow),
                color: Colors.amber,
              ),
              _HudStat(
                label: '💸 Chi Phí',
                value: CurrencyFormatter.compact(gs.totalMonthlyExpenses),
                color: AppColors.danger,
              ),
            ],
          ),

          const Gap(AppSizes.md),

          // Financial Freedom Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🎯 Tiến Độ Thoát Rat Race',
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: progress >= 1.0
                          ? AppColors.success
                          : AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Gap(4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white12,
                  color: progress >= 1.0
                      ? AppColors.success
                      : AppColors.primary,
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSpaceInfo(GameState gs) {
    final spaceType = gs.boardPosition < 24
        ? _ratRaceBoard[gs.boardPosition]
        : _ratRaceBoard[0];
    final label = _spaceLabelOf(spaceType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          const Gap(8),
          Text(
            '• Ô ${gs.boardPosition + 1}/24',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceSection(GameUiPlaying state) {
    final isDisabled = state.isRolling || state.currentEvent != null;
    return Column(
      children: [
        DiceWidget(
          value: state.lastDiceValue,
          isRolling: state.isRolling,
          onTap: () {
            AudioPlayerManager().vibrate();
            ref.read(cashflowGameProvider.notifier).rollDice();
          },
        ),
        const Gap(AppSizes.md),
        if (state.gameState.downsizeTurns > 0)
          Text(
            '❌ Đang thất nghiệp (còn ${state.gameState.downsizeTurns} lượt)',
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ).animate().shake(),
        const Gap(AppSizes.sm),
        SizedBox(
          width: 220,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDisabled
                  ? Colors.grey.shade700
                  : AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl)),
            ),
            onPressed: isDisabled
                ? null
                : () => ref
                    .read(cashflowGameProvider.notifier)
                    .rollDice(),
            icon: const Text('🎲', style: TextStyle(fontSize: 20)),
            label: Text(
              state.isRolling ? 'Đang Tung...' : 'TUNG XÚC XẮC',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ).animate().fadeIn(),
      ],
    );
  }



  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevatedDark,
        title: const Text('Chơi Lại?'),
        content: const Text(
          'Toàn bộ tiến trình sẽ bị xoá. Bạn chắc chắn?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(cashflowGameProvider.notifier)
                  .resetGame();
            },
            child: const Text('Chơi Lại'),
          ),
        ],
      ),
    );
  }

  void _showWinDialog(GameState gs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevatedDark,
        title: const Text('🎉 Chúc Mừng!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bạn đã THOÁT KHỎI RAT RACE!\nThu nhập thụ động đã vượt qua chi phí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const Gap(AppSizes.md),
            Text(
              'Thu nhập thụ động: ${CurrencyFormatter.compact(gs.passiveIncome)}/tháng',
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cashflowGameProvider.notifier).resetGame();
            },
            child: const Text('Chơi Lại'),
          ),
        ],
      ),
    );
  }

  void _showLoseDialog(GameState gs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevatedDark,
        title: const Text('💸 Phá Sản!', textAlign: TextAlign.center),
        content: const Text(
          'Tiền mặt âm quá nhiều, bạn không thể tiếp tục.\nHãy thử lại với chiến lược khác!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              ref.read(cashflowGameProvider.notifier).resetGame();
            },
            child: const Text('Thử Lại'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────
class _HudStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HudStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const Gap(2),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}



final _ratRaceBoard = ratRaceBoard;

String _spaceLabelOf(BoardSpaceType type) => switch (type) {
      BoardSpaceType.paycheck => '💰 Nhận Lương',
      BoardSpaceType.opportunity => '⭐ Cơ Hội Đầu Tư',
      BoardSpaceType.doodad => '🛒 Tiêu Sản Bất Ngờ',
      BoardSpaceType.market => '📈 Tin Thị Trường',
      BoardSpaceType.baby => '👶 Em Bé Chào Đời',
      BoardSpaceType.downsize => '❌ Sa Thải',
      BoardSpaceType.charity => '❤️ Từ Thiện',
    };
