import 'dart:async';
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
import 'package:fin_goal/features/cashflow_game/presentation/widgets/fast_track_board_widget.dart';
import 'package:fin_goal/features/cashflow_game/presentation/widgets/financial_report_dialog.dart';
import 'package:fin_goal/features/cashflow_game/presentation/widgets/game_guide_dialog.dart';
import 'package:fin_goal/features/cashflow_game/presentation/pages/occupation_select_page.dart';
import 'package:fin_goal/features/cashflow_game/engine/board_engine.dart';
import 'package:fin_goal/core/utils/audio_player_manager.dart';
import 'package:fin_goal/features/cashflow_game/presentation/providers/audio_provider.dart';
import 'package:fin_goal/core/presentation/widgets/banner_ad_widget.dart';
import 'package:fin_goal/core/services/ad_service.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fin_goal/features/premium/presentation/providers/subscription_provider.dart';

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
    final isMuted = ref.watch(audioProvider);

    // React to event card appearance
    ref.listen<CashflowGameUiState>(cashflowGameProvider, (prev, next) {
      if (next is GameUiPlaying && next.currentEvent != null) {
        if (prev is! GameUiPlaying || prev.currentEvent == null) {
          AudioPlayerManager().playSfx('audio/card_flip.wav');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showEventCard(next);
        });
      }
      if (next is GameUiFinanciallyFree) {
        _showWinDialog(next.gameState);
      }
      if (next is GameUiWon) {
        _showUltimateWinDialog(next.gameState);
      }
      if (next is GameUiBankrupt) {
        _showLoseDialog(next.gameState);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(uiState, isMuted),
      body: _buildBody(uiState),
    );
  }

  PreferredSizeWidget _buildAppBar(CashflowGameUiState s, bool isMuted) {
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
            icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
            tooltip: isMuted ? 'Bật Âm Thanh' : 'Tắt Âm Thanh',
            onPressed: () => ref.read(audioProvider.notifier).toggleMute(),
          ),
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
      GameUiWon() => const SizedBox.shrink(),
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
                  child: gs.isFastTrack
                      ? FastTrackBoardWidget(
                          currentPosition: gs.boardPosition,
                          size: screenWidth - 32,
                        )
                      : RatRaceBoardWidget(
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
        if (!ref.watch(isPremiumUserProvider)) const BannerAdWidget(),
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
              AnimatedCashStatWidget(cashOnHand: gs.cashOnHand),
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

          if (!ref.watch(isPremiumUserProvider)) ...[
            const Gap(AppSizes.md),
            _CooldownRewardedAdButton(
              lastWatchedTime: state is GameUiPlaying ? state.lastAdWatchedTime : null,
              onWatch: () {
                AdService.showRewardedAd(context, () {
                  ref.read(cashflowGameProvider.notifier).addCash(500000);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã nhận 500K từ nhà tài trợ!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                });
              },
            ),
          ],

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
    final board = gs.isFastTrack ? fastTrackBoard : ratRaceBoard;
    final bSize = gs.isFastTrack ? fastTrackBoardSize : boardSize;
    final spaceType = gs.boardPosition < bSize
        ? board[gs.boardPosition]
        : board[0];
    final label = BoardEngine.getSpaceLabel(spaceType);

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
    final diceValues = state.lastDiceValues ?? [1];

    void handleRoll() {
      if (isDisabled) return;
      AudioPlayerManager().vibrate();
      AudioPlayerManager().playSfx('audio/dice_roll.wav');
      ref.read(cashflowGameProvider.notifier).rollDice();
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DiceWidget(
              value: diceValues.isNotEmpty ? diceValues[0] : 1,
              isRolling: state.isRolling,
              onTap: handleRoll,
            ),
            if (state.gameState.isFastTrack) ...[
              const Gap(AppSizes.md),
              DiceWidget(
                value: diceValues.length > 1 ? diceValues[1] : 1,
                isRolling: state.isRolling,
                onTap: handleRoll,
              ),
            ],
          ],
        ),
        const Gap(AppSizes.md),
        if (state.gameState.downsizeTurns > 0)
          Text(
            '❌ Đang thất nghiệp (còn ${state.gameState.downsizeTurns} lượt)',
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ).animate().shake(),
        if (kDebugMode && !state.gameState.isFastTrack) ...[
          const Gap(AppSizes.sm),
          TextButton.icon(
            icon: const Icon(Icons.bug_report, color: Colors.amber),
            label: const Text('DEV: Cheat Thoát Rat Race', style: TextStyle(color: Colors.amber)),
            onPressed: () {
              ref.read(cashflowGameProvider.notifier).devForceWinRatRace();
            },
          ),
        ],
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
          TextButton.icon(
            icon: const Icon(Icons.assessment, color: Colors.blueAccent),
            label: const Text('Báo Cáo'),
            onPressed: () => FinancialReportDialog.show(context, gs),
          ),
          TextButton.icon(
            icon: const Icon(Icons.share, color: Colors.greenAccent),
            label: const Text('Chia Sẻ'),
            onPressed: () => Share.share('Tôi đã thoát khỏi Rat Race trong game Cashflow với thu nhập thụ động ${CurrencyFormatter.compact(gs.passiveIncome)}/tháng!'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(context);
              ref.read(cashflowGameProvider.notifier).enterFastTrack();
            },
            child: const Text('VÀO FAST TRACK 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cashflowGameProvider.notifier).resetGame();
            },
            child: const Text('Chơi Lại', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showUltimateWinDialog(GameState gs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.amber.shade900,
        title: const Text('🏆 CHIẾN THẮNG TUYỆT ĐỐI! 🏆', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎆 🎆 🎆', style: TextStyle(fontSize: 40)),
            const Gap(AppSizes.md),
            const Text(
              'Bạn đã đạt được Ước Mơ hoặc xây dựng được dòng tiền khổng lồ trên Fast Track!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const Gap(AppSizes.lg),
            Text(
              'Thu nhập thụ động: ${CurrencyFormatter.compact(gs.passiveIncome)}',
              style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.assessment),
            label: const Text('Báo Cáo'),
            onPressed: () => FinancialReportDialog.show(context, gs),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            icon: const Icon(Icons.share),
            label: const Text('Chia Sẻ'),
            onPressed: () => Share.share('Tôi đã trở thành Tỷ Phú trong game Cashflow với thu nhập thụ động ${CurrencyFormatter.compact(gs.passiveIncome)}/tháng! 🏆🏆🏆'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.amber.shade900),
            onPressed: () {
              Navigator.pop(context);
              if (!ref.read(isPremiumUserProvider)) {
                AdService.showInterstitialAd(onAdClosed: () {
                  ref.read(cashflowGameProvider.notifier).resetGame();
                });
              } else {
                ref.read(cashflowGameProvider.notifier).resetGame();
              }
            },
            child: const Text('Chơi Lại Từ Đầu', style: TextStyle(fontWeight: FontWeight.bold)),
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
              if (!ref.read(isPremiumUserProvider)) {
                AdService.showInterstitialAd(onAdClosed: () {
                  ref.read(cashflowGameProvider.notifier).resetGame();
                });
              } else {
                ref.read(cashflowGameProvider.notifier).resetGame();
              }
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

class AnimatedCashStatWidget extends StatefulWidget {
  final int cashOnHand;

  const AnimatedCashStatWidget({super.key, required this.cashOnHand});

  @override
  State<AnimatedCashStatWidget> createState() => _AnimatedCashStatWidgetState();
}

class _AnimatedCashStatWidgetState extends State<AnimatedCashStatWidget> {
  int _diff = 0;
  Key _animKey = UniqueKey();

  @override
  void didUpdateWidget(covariant AnimatedCashStatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cashOnHand != oldWidget.cashOnHand) {
      _diff = widget.cashOnHand - oldWidget.cashOnHand;
      _animKey = UniqueKey(); // trigger animation rebuild
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        _HudStat(
          label: '💰 Tiền Mặt',
          value: CurrencyFormatter.compact(widget.cashOnHand),
          color: Colors.white,
        ),
        if (_diff != 0)
          Positioned(
            top: -15,
            child: Text(
              _diff > 0 
                  ? '+${CurrencyFormatter.compact(_diff)}' 
                  : '-${CurrencyFormatter.compact(_diff.abs())}',
              style: TextStyle(
                color: _diff > 0 ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            )
            .animate(key: _animKey)
            .fadeIn(duration: 200.ms)
            .moveY(begin: 0, end: -15, duration: 800.ms, curve: Curves.easeOut)
            .fadeOut(delay: 600.ms, duration: 200.ms),
          ),
      ],
    );
  }
}

class _CooldownRewardedAdButton extends StatefulWidget {
  final DateTime? lastWatchedTime;
  final VoidCallback onWatch;

  const _CooldownRewardedAdButton({
    required this.lastWatchedTime,
    required this.onWatch,
  });

  @override
  State<_CooldownRewardedAdButton> createState() => _CooldownRewardedAdButtonState();
}

class _CooldownRewardedAdButtonState extends State<_CooldownRewardedAdButton> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateCooldown();
  }

  @override
  void didUpdateWidget(covariant _CooldownRewardedAdButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastWatchedTime != oldWidget.lastWatchedTime) {
      _updateCooldown();
    }
  }

  void _updateCooldown() {
    _timer?.cancel();
    if (widget.lastWatchedTime == null) {
      setState(() => _remainingSeconds = 0);
      return;
    }
    
    final diff = DateTime.now().difference(widget.lastWatchedTime!).inSeconds;
    if (diff < 10) {
      _remainingSeconds = 10 - diff;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final newDiff = DateTime.now().difference(widget.lastWatchedTime!).inSeconds;
        if (newDiff >= 10) {
          setState(() => _remainingSeconds = 0);
          timer.cancel();
        } else {
          setState(() => _remainingSeconds = 10 - newDiff);
        }
      });
    } else {
      setState(() => _remainingSeconds = 0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = _remainingSeconds > 0;
    
    return InkWell(
      onTap: isDisabled ? null : widget.onWatch,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDisabled ? Colors.grey.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ondemand_video, size: 16, color: isDisabled ? Colors.grey : Colors.amber),
            const Gap(6),
            Text(
              isDisabled ? 'Chờ 00:${_remainingSeconds.toString().padLeft(2, '0')}' : 'Xem video nhận 500K',
              style: TextStyle(
                color: isDisabled ? Colors.grey : Colors.amber, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}
