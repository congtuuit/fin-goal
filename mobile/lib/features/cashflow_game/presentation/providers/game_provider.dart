import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/occupation.dart';
import 'package:fin_goal/features/cashflow_game/data/repositories/game_repository.dart';
import 'package:fin_goal/features/cashflow_game/engine/board_engine.dart';
import 'package:fin_goal/features/cashflow_game/engine/economy_engine.dart';
import 'package:fin_goal/features/cashflow_game/engine/event_engine.dart';
import 'package:fin_goal/core/utils/audio_player_manager.dart';

part 'game_provider.g.dart';

// ── Repository ───────────────────────────────────────────────────────────────
@riverpod
GameRepository gameRepository(Ref ref) =>
    GameRepository(getIt<SharedPreferences>());

// ── Engines ──────────────────────────────────────────────────────────────────
@riverpod
BoardEngine boardEngine(Ref ref) => BoardEngine();

@riverpod
EconomyEngine economyEngine(Ref ref) => EconomyEngine();

@riverpod
EventEngine eventEngine(Ref ref) => EventEngine();

// ── UI State ─────────────────────────────────────────────────────────────────
sealed class CashflowGameUiState {
  const CashflowGameUiState();
}

class GameUiLoading extends CashflowGameUiState {
  const GameUiLoading();
}

class GameUiSelectOccupation extends CashflowGameUiState {
  const GameUiSelectOccupation();
}

class GameUiPlaying extends CashflowGameUiState {
  final GameState gameState;
  final EventCard? currentEvent;
  final bool isRolling;
  final int? lastDiceValue;

  const GameUiPlaying({
    required this.gameState,
    this.currentEvent,
    this.isRolling = false,
    this.lastDiceValue,
  });

  GameUiPlaying copyWith({
    GameState? gameState,
    EventCard? currentEvent,
    bool clearEvent = false,
    bool? isRolling,
    int? lastDiceValue,
  }) =>
      GameUiPlaying(
        gameState: gameState ?? this.gameState,
        currentEvent: clearEvent ? null : (currentEvent ?? this.currentEvent),
        isRolling: isRolling ?? this.isRolling,
        lastDiceValue: lastDiceValue ?? this.lastDiceValue,
      );
}

class GameUiFinanciallyFree extends CashflowGameUiState {
  final GameState gameState;
  const GameUiFinanciallyFree(this.gameState);
}

class GameUiWon extends CashflowGameUiState {
  final GameState gameState;
  const GameUiWon(this.gameState);
}

class GameUiBankrupt extends CashflowGameUiState {
  final GameState gameState;
  const GameUiBankrupt(this.gameState);
}

class GameUiError extends CashflowGameUiState {
  final String message;
  const GameUiError(this.message);
}

// ── Notifier ─────────────────────────────────────────────────────────────────
@riverpod
class CashflowGameNotifier extends _$CashflowGameNotifier {
  @override
  CashflowGameUiState build() {
    _init();
    return const GameUiLoading();
  }

  Future<void> _init() async {
    final playerId =
        ref.read(currentUserProvider)?.id ?? 'offline_player';
    final repo = ref.read(gameRepositoryProvider);
    final saved = await repo.loadGame(playerId);
    if (saved != null) {
      state = GameUiPlaying(gameState: saved);
    } else {
      state = const GameUiSelectOccupation();
    }
  }

  // ── Chọn Nghề Nghiệp ──────────────────────────────────────────────────────
  Future<void> startGame(Occupation occupation) async {
    final playerId =
        ref.read(currentUserProvider)?.id ?? 'offline_player';

    final initialState = GameState(
      playerId: playerId,
      occupation: occupation,
      cashOnHand: occupation.initialCash,
      monthlyIncome: occupation.monthlySalary,
      monthlyExpenses: occupation.monthlyExpenses,
      creditScore: occupation.initialCreditScore,
      liabilities: occupation.initialDebt > 0
          ? [
              Liability(
                id: 'initial_debt_${DateTime.now().millisecondsSinceEpoch}',
                name: 'Nợ Ban Đầu (Học phí, Nhà, Xe)',
                totalOwed: occupation.initialDebt,
                monthlyPayment: occupation.monthlyLoanPayment,
              )
            ]
          : [],
    );

    await ref.read(gameRepositoryProvider).saveGame(initialState);
    state = GameUiPlaying(gameState: initialState);
  }

  // ── Tung Xúc Xắc ──────────────────────────────────────────────────────────
  Future<void> rollDice() async {
    if (state is! GameUiPlaying) return;
    final current = state as GameUiPlaying;
    if (current.isRolling || current.currentEvent != null) return;

    // Kiểm tra mất lượt
    if (current.gameState.downsizeTurns > 0) {
      final newGs = current.gameState.copyWith(
        downsizeTurns: current.gameState.downsizeTurns - 1,
        currentTurn: current.gameState.currentTurn + 1,
      );
      await _save(newGs);
      state = current.copyWith(
        gameState: newGs,
        currentEvent: _downsizeSkipCard(),
      );
      return;
    }

    state = current.copyWith(isRolling: true);
    await Future.delayed(const Duration(milliseconds: 600)); // animation dice

    final engine = ref.read(boardEngineProvider);
    int diceValue = engine.rollDice();
    if (current.gameState.isFastTrack) {
      diceValue += engine.rollDice(); // Roll 2 dice in Fast Track
    }
    final move = engine.move(
      current.gameState.boardPosition, 
      diceValue, 
      isFastTrack: current.gameState.isFastTrack
    );

    var newGs = current.gameState.copyWith(
      boardPosition: move.newPosition,
      currentTurn: current.gameState.currentTurn + 1,
    );

    // Nhận lương khi đi qua ô paycheck
    if (move.crossedPaycheck) {
      AudioPlayerManager().playSfx('audio/payday.wav');
      final paycheckAmount = newGs.isFastTrack
          ? newGs.fastTrackIncome * move.paychecksReceived
          : newGs.monthlyCashflow * move.paychecksReceived;
      newGs = newGs.copyWith(
        cashOnHand: newGs.cashOnHand + paycheckAmount,
      );
    }

    // Áp dụng lạm phát mỗi 12 lượt (1 năm)
    if (newGs.currentTurn % 12 == 0) {
      newGs = _applyInflation(newGs);
    }

    // Chuyển trạng thái kinh tế mỗi 6 lượt
    if (newGs.currentTurn % 6 == 0) {
      final econEngine = ref.read(economyEngineProvider);
      final nextEconomy = econEngine.nextEconomyState(newGs.economyState);
      newGs = newGs.copyWith(economyState: nextEconomy);
    }

    // Lấy thẻ bài sự kiện
    final eventEngine = ref.read(eventEngineProvider);
    final econEngine = ref.read(economyEngineProvider);
    final positiveEventBias =
        econEngine.getPositiveEventBias(newGs.economyState);
    final isPositive =
        ref.read(boardEngineProvider).rollDice() / 6.0 <= positiveEventBias;

    final eventCard = eventEngine.getEventCard(
      move.landedSpace,
      newGs,
      positive: isPositive,
    );

    await _save(newGs);
    state = current.copyWith(
      gameState: newGs,
      currentEvent: eventCard,
      isRolling: false,
      lastDiceValue: diceValue,
    );
  }

  // ── Áp Dụng Lựa Chọn Thẻ Bài ─────────────────────────────────────────────
  Future<void> applyChoice(EventChoice choice) async {
    if (state is! GameUiPlaying) return;
    final current = state as GameUiPlaying;
    final impact = choice.impact;
    var gs = current.gameState;

    if (impact.newAssetName != null || impact.cashChange > 0) {
      AudioPlayerManager().playSfx('audio/success.wav');
    }

    // Tiền mặt
    int newCash = gs.cashOnHand + impact.cashChange;

    // Fast Track Audit: Mất 50% tiền mặt
    if (choice.id == 'ft_audit_pay') {
      newCash = (gs.cashOnHand / 2).floor();
    }

    // Charity: trừ 10% thu nhập
    if (choice.id == 'charity_yes') {
      newCash -= (gs.totalMonthlyIncome * 0.1).round();
    }

    // Downsize: trừ chi phí 1 tháng
    if (choice.id == 'downsize_ok') {
      newCash -= gs.totalMonthlyExpenses;
    }

    // Baby: thêm con
    final newChildren =
        impact.addChild ? gs.children + 1 : gs.children;

    // Downsize turns
    final newDownsize = impact.downsizeTurns > 0
        ? impact.downsizeTurns
        : gs.downsizeTurns;

    // Tài sản mới
    var newAssets = List<Asset>.from(gs.assets);
    if (impact.newAssetName != null) {
      newAssets.add(Asset(
        id: 'asset_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
        name: impact.newAssetName!,
        type: impact.newAssetType ?? AssetType.other,
        purchasePrice: impact.newAssetValue ?? 0,
        currentValue: impact.newAssetValue ?? 0,
        monthlyPassiveIncome: impact.newAssetPassiveIncome ?? 0,
        downPayment: impact.downPayment ?? 0,
        mortgage: impact.mortgage ?? 0,
        monthlyMortgagePayment: impact.monthlyMortgagePayment ?? 0,
      ));
    }

    // Nợ mới
    var newLiabilities = List<Liability>.from(gs.liabilities);
    if (impact.newLiabilityName != null) {
      newLiabilities.add(Liability(
        id: 'liability_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
        name: impact.newLiabilityName!,
        totalOwed: impact.newLiabilityAmount ?? 0,
        monthlyPayment: impact.newLiabilityMonthlyPayment ?? 0,
      ));
    }

    // XP
    final xpGain = _calculateXp(choice, gs);
    final newXp = gs.xp + xpGain;
    final newLevel = (newXp / 500).floor() + 1;

    gs = gs.copyWith(
      cashOnHand: newCash,
      children: newChildren,
      downsizeTurns: newDownsize,
      assets: newAssets,
      liabilities: newLiabilities,
      creditScore: gs.creditScore + impact.creditScoreChange,
      xp: newXp,
      level: newLevel.clamp(1, 50),
    );

    await _save(gs);

    // Kiểm tra win/lose
    if (gs.isFastTrackWinner) {
      state = GameUiWon(gs);
      return;
    }
    if (gs.isFinanciallyFree && !gs.isFastTrack) {
      state = GameUiFinanciallyFree(gs);
      return;
    }
    if (gs.isBankrupt) {
      state = GameUiBankrupt(gs);
      return;
    }

    state = current.copyWith(gameState: gs, clearEvent: true);
  }

  // ── Lạm Phát ──────────────────────────────────────────────────────────────
  GameState _applyInflation(GameState gs) {
    final econEngine = ref.read(economyEngineProvider);
    final newRate = econEngine.getInflationRate(gs.economyState);
    return gs.copyWith(inflationRate: newRate);
  }

  // ── Utilities ──────────────────────────────────────────────────────────────
  int _calculateXp(EventChoice choice, GameState gs) {
    // Phần thưởng XP cho các hành động tốt
    if (choice.id.startsWith('sd_') || choice.id.startsWith('bd_')) {
      return choice.id.contains('_buy') || choice.id.contains('_invest')
          ? 50
          : 10;
    }
    if (choice.id == 'charity_yes') return 30;
    if (choice.id == 'dd_phone_skip') return 40;
    return 5;
  }

  EventCard _downsizeSkipCard() => const EventCard(
        id: 'skip_turn_downsize',
        title: '⏸️ Mất Lượt (Đang Thất Nghiệp)',
        description:
            'Bạn đang trong giai đoạn tìm việc sau khi bị sa thải. Lượt này bị bỏ qua.',
        type: EventType.downsize,
        choices: [
          EventChoice(
            id: 'skip_ok',
            label: 'Tiếp Tục',
            shortDescription: 'Chờ lượt sau',
            teachingMoment:
                'Khi thu nhập thụ động lớn hơn chi phí, bạn sẽ không cần lo lắng về việc mất lương nữa.',
            impact: EventImpact(),
          ),
        ],
      );

  // ── Trả nợ (Phase 3) ────────────────────────────────────────────────────────
  Future<void> payDebt(String liabilityId, int amount) async {
    if (state is! GameUiPlaying) return;
    final current = state as GameUiPlaying;
    final gs = current.gameState;

    if (gs.cashOnHand < amount) return;

    final targetIdx = gs.liabilities.indexWhere((l) => l.id == liabilityId);
    if (targetIdx == -1) return;

    AudioPlayerManager().playSfx('audio/success.wav');

    final oldLiability = gs.liabilities[targetIdx];
    final actualPayment = min(amount, oldLiability.totalOwed);

    final newOwed = oldLiability.totalOwed - actualPayment;
    var newLiabilities = List<Liability>.from(gs.liabilities);

    if (newOwed <= 0) {
      newLiabilities.removeAt(targetIdx);
    } else {
      final ratio = newOwed / oldLiability.totalOwed;
      final newMonthly = (oldLiability.monthlyPayment * ratio).round();
      newLiabilities[targetIdx] = oldLiability.copyWith(
        totalOwed: newOwed,
        monthlyPayment: newMonthly,
      );
    }

    final newGs = gs.copyWith(
      cashOnHand: gs.cashOnHand - actualPayment,
      liabilities: newLiabilities,
    );

    await _save(newGs);

    if (newGs.isFinanciallyFree && !gs.isFinanciallyFree) {
      state = GameUiFinanciallyFree(newGs);
    } else {
      state = current.copyWith(gameState: newGs);
    }
  }

  Future<void> _save(GameState gs) async {
    await ref.read(gameRepositoryProvider).saveGame(gs);
  }

  // ── Vào Fast Track ─────────────────────────────────────────────────────────
  Future<void> enterFastTrack() async {
    GameState? currentGs;
    if (state is GameUiPlaying) {
      currentGs = (state as GameUiPlaying).gameState;
    } else if (state is GameUiFinanciallyFree) {
      currentGs = (state as GameUiFinanciallyFree).gameState;
    }

    if (currentGs == null) return;

    final newIncome = currentGs.passiveIncome * 100;
    
    final fastTrackGs = currentGs.copyWith(
      isFastTrack: true,
      fastTrackIncome: newIncome,
      cashOnHand: newIncome,
      boardPosition: 0,
      assets: [],
      liabilities: [],
    );

    await _save(fastTrackGs);
    state = GameUiPlaying(gameState: fastTrackGs);
  }

  // ── Dev Cheat ──────────────────────────────────────────────────────────────
  Future<void> devForceWinRatRace() async {
    if (state is! GameUiPlaying) return;
    final gs = (state as GameUiPlaying).gameState;
    
    final newAsset = Asset(
      id: 'dev_asset',
      name: 'DEV Cheat Asset',
      type: AssetType.business,
      purchasePrice: 0,
      currentValue: 0,
      monthlyPassiveIncome: gs.totalMonthlyExpenses + 10000,
      downPayment: 0,
      mortgage: 0,
      monthlyMortgagePayment: 0,
    );
    
    final newGs = gs.copyWith(
      assets: [...gs.assets, newAsset],
    );
    
    await _save(newGs);
    state = GameUiFinanciallyFree(newGs);
  }

  // ── Reset Game ─────────────────────────────────────────────────────────────
  Future<void> resetGame() async {
    final playerId =
        ref.read(currentUserProvider)?.id ?? 'offline_player';
    await ref.read(gameRepositoryProvider).deleteGame(playerId);
    state = const GameUiSelectOccupation();
  }
}
