import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/core/services/ai_provider.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';
import 'package:fin_goal/features/cashflow/domain/entities/cashflow_state.dart';
import 'package:fin_goal/features/cashflow/domain/entities/game_scenario.dart';
import 'package:fin_goal/features/cashflow/domain/repositories/cashflow_repository.dart';
import 'package:fin_goal/features/cashflow/data/repositories/local_cashflow_repository_impl.dart';
import 'package:fin_goal/features/cashflow/domain/entities/board_space.dart';
import 'package:fin_goal/features/cashflow/engine/board_game_engine.dart';
import 'package:fin_goal/features/cashflow/engine/cashflow_ai_engine.dart';

part 'cashflow_provider.g.dart';

@riverpod
CashflowRepository cashflowRepository(Ref ref) {
  return LocalCashflowRepositoryImpl(getIt<SharedPreferences>());
}

@riverpod
CashflowAiEngine cashflowAiEngine(Ref ref) {
  final aiService = ref.read(aiServiceProvider);
  return CashflowAiEngine(aiService);
}

@riverpod
BoardGameEngine boardGameEngine(Ref ref) {
  return BoardGameEngine();
}

sealed class CashflowGameState {
  const CashflowGameState();
}

class CashflowGameLoading extends CashflowGameState {
  const CashflowGameLoading();
}

class CashflowGameReady extends CashflowGameState {
  final CashflowState state;
  final GameScenario? currentScenario;
  final bool isGeneratingScenario;

  const CashflowGameReady({
    required this.state,
    this.currentScenario,
    this.isGeneratingScenario = false,
  });
  
  CashflowGameReady copyWith({
    CashflowState? state,
    GameScenario? currentScenario,
    bool? isGeneratingScenario,
    bool clearScenario = false,
  }) {
    return CashflowGameReady(
      state: state ?? this.state,
      currentScenario: clearScenario ? null : (currentScenario ?? this.currentScenario),
      isGeneratingScenario: isGeneratingScenario ?? this.isGeneratingScenario,
    );
  }
}

class CashflowGameError extends CashflowGameState {
  final String message;
  const CashflowGameError(this.message);
}

@riverpod
class CashflowNotifier extends _$CashflowNotifier {
  @override
  CashflowGameState build() {
    _loadState();
    return const CashflowGameLoading();
  }

  Future<void> _loadState() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) {
      state = const CashflowGameError('Vui lòng đăng nhập.');
      return;
    }

    final repo = ref.read(cashflowRepositoryProvider);
    final result = await repo.getCashflowState(userId);

    result.fold(
      (failure) => state = CashflowGameError(failure.message),
      (cashflowState) {
        if (cashflowState != null) {
          state = CashflowGameReady(state: cashflowState);
        } else {
          // Khởi tạo state mới từ FinancialProfile
          _initializeFromProfile(userId);
        }
      },
    );
  }

  Future<void> _initializeFromProfile(String userId) async {
    final profileState = ref.read(profileProvider);
    if (profileState is! ProfileLoaded || profileState.profile == null) {
      state = const CashflowGameError('Không thể lấy thông tin tài chính gốc.');
      return;
    }

    final profile = profileState.profile!;
    
    final initialState = CashflowState(
      userId: userId,
      currentMonth: 1,
      cashOnHand: 0, // Bắt đầu từ 0 hoặc lấy từ tổng currentSavings của các goal
      activeIncome: profile.monthlyIncome,
      baseExpenses: profile.fixedExpenses,
      assets: const [],
      liabilities: const [],
    );

    final repo = ref.read(cashflowRepositoryProvider);
    await repo.saveCashflowState(initialState);
    
    state = CashflowGameReady(state: initialState);
  }

  Future<void> rollDiceAndMove() async {
    if (state is! CashflowGameReady) return;
    final currentState = state as CashflowGameReady;
    
    // Kiểm tra mất lượt
    if (currentState.state.downsizeTurns > 0) {
      final newState = currentState.state.copyWith(
        downsizeTurns: currentState.state.downsizeTurns - 1
      );
      await ref.read(cashflowRepositoryProvider).saveCashflowState(newState);
      state = currentState.copyWith(
        state: newState,
        currentScenario: const GameScenario(
          id: 'skip_turn',
          title: 'Bị mất lượt',
          description: 'Bạn đang trong giai đoạn thất nghiệp nên bị mất 1 lượt đi.',
          options: [
            GameOption(
              id: 'skip_ok',
              title: 'Chấp nhận',
              description: 'Kết thúc lượt',
              aiFeedback: 'Hãy kiên nhẫn vượt qua khủng hoảng.',
              impact: GameImpact(),
            )
          ]
        ),
      );
      return;
    }

    state = currentState.copyWith(isGeneratingScenario: true);

    try {
      final boardEngine = ref.read(boardGameEngineProvider);
      
      // Tung xúc xắc
      final dice = boardEngine.rollDice();
      final moveResult = boardEngine.move(currentState.state.boardPosition, dice);
      
      // Cập nhật state (di chuyển)
      var newState = currentState.state.copyWith(
        boardPosition: moveResult.newPosition,
      );
      
      // Xử lý đi ngang qua hoặc vào ô Paycheck
      if (moveResult.crossedPaycheck) {
        // Cộng 1 tháng lương (cashflow)
        newState = newState.copyWith(
          cashOnHand: newState.cashOnHand + newState.monthlyCashflow,
          currentMonth: newState.currentMonth + 1,
        );
      }

      await ref.read(cashflowRepositoryProvider).saveCashflowState(newState);

      // Bốc bài
      GameScenario? scenario = boardEngine.getScenarioForSpace(moveResult.landedSpace);
      
      // Nếu là ô cần AI sinh (như Opportunity)
      if (scenario == null && moveResult.landedSpace == SpaceType.opportunity) {
        final aiEngine = ref.read(cashflowAiEngineProvider);
        scenario = await aiEngine.generateScenario(newState);
      }
      
      // Nếu bốc bài thất bại, tạo bài dự phòng
      scenario ??= GameScenario(
        id: 'empty_space',
        title: 'Ô trống',
        description: 'Bạn vừa bước vào ô không có sự kiện gì đặc biệt.',
        options: const [
          GameOption(
            id: 'ok',
            title: 'Tiếp tục',
            description: 'Kết thúc lượt',
            aiFeedback: 'May mắn là không có chuyện gì tồi tệ xảy ra.',
            impact: GameImpact(),
          )
        ],
      );
      
      state = currentState.copyWith(
        state: newState,
        currentScenario: scenario,
        isGeneratingScenario: false,
      );
    } catch (e) {
      state = currentState.copyWith(isGeneratingScenario: false);
      throw Exception('Lỗi khi tung xúc xắc: \$e');
    }
  }

  Future<void> applyOption(GameOption option) async {
    if (state is! CashflowGameReady) return;
    final currentState = state as CashflowGameReady;
    
    // Apply impact
    final impact = option.impact;
    var newState = currentState.state;
    
    // 1. Cập nhật tiền mặt (thu nhập hàng tháng ĐÃ được cộng ở hàm tung xúc xắc qua vạch)
    // Chỉ cộng trừ theo lựa chọn của kịch bản
    final newCashOnHand = newState.cashOnHand + impact.cashChange;
    
    // 2. Cập nhật tài sản
    final updatedAssets = List<CashflowAsset>.from(newState.assets);
    if (impact.removedAssetIds != null) {
      updatedAssets.removeWhere((a) => impact.removedAssetIds!.contains(a.id));
    }
    if (impact.addedAssets != null) {
      updatedAssets.addAll(impact.addedAssets!);
    }
    
    // 3. Cập nhật tiêu sản
    final updatedLiabilities = List<CashflowLiability>.from(newState.liabilities);
    if (impact.removedLiabilityIds != null) {
      updatedLiabilities.removeWhere((l) => impact.removedLiabilityIds!.contains(l.id));
    }
    if (impact.addedLiabilities != null) {
      updatedLiabilities.addAll(impact.addedLiabilities!);
    }
    
    // 4. Các yếu tố đặc biệt (Baby, Downsize)
    int newChildren = newState.children;
    if (option.id == 'baby_ok') newChildren++;
    
    int newDownsize = newState.downsizeTurns;
    int additionalExpenses = 0;
    if (option.id == 'downsize_ok') {
      newDownsize = 2; // Mất 2 lượt
      additionalExpenses = currentState.state.totalExpenses; // Trừ chi phí cố định cho 1 tháng
    }

    // 4. Cập nhật state
    newState = newState.copyWith(
      cashOnHand: newCashOnHand - additionalExpenses,
      activeIncome: newState.activeIncome + impact.activeIncomeChange,
      baseExpenses: newState.baseExpenses + impact.baseExpensesChange,
      children: newChildren,
      downsizeTurns: newDownsize,
      assets: updatedAssets,
      liabilities: updatedLiabilities,
    );

    // Save
    await ref.read(cashflowRepositoryProvider).saveCashflowState(newState);

    state = currentState.copyWith(
      state: newState,
      clearScenario: true,
    );
  }

  Future<void> resetGame() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null) {
      state = const CashflowGameLoading();
      await ref.read(cashflowRepositoryProvider).resetCashflowState(userId);
      await _initializeFromProfile(userId);
    }
  }
}
