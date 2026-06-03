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

  Future<void> generateNextScenario() async {
    if (state is! CashflowGameReady) return;
    final currentState = state as CashflowGameReady;
    
    state = currentState.copyWith(isGeneratingScenario: true);

    try {
      final engine = ref.read(cashflowAiEngineProvider);
      final scenario = await engine.generateScenario(currentState.state);
      
      state = currentState.copyWith(
        currentScenario: scenario,
        isGeneratingScenario: false,
      );
    } catch (e) {
      state = currentState.copyWith(isGeneratingScenario: false);
      // Gửi lỗi (có thể dùng Toast trong UI)
      throw Exception('Lỗi khi tạo kịch bản AI: \$e');
    }
  }

  Future<void> applyOption(GameOption option) async {
    if (state is! CashflowGameReady) return;
    final currentState = state as CashflowGameReady;
    
    // Apply impact
    final impact = option.impact;
    var newState = currentState.state;
    
    // 1. Cập nhật tiền mặt (thu nhập hàng tháng + cashChange từ lựa chọn)
    // Coi như đã qua 1 tháng, ta cộng dòng tiền vào cashOnHand trước khi áp dụng impact
    final newCashOnHand = newState.cashOnHand + newState.monthlyCashflow + impact.cashChange;
    
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
    
    // 4. Cập nhật thu nhập/chi phí
    newState = newState.copyWith(
      currentMonth: newState.currentMonth + 1,
      cashOnHand: newCashOnHand,
      activeIncome: newState.activeIncome + impact.activeIncomeChange,
      baseExpenses: newState.baseExpenses + impact.baseExpensesChange,
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
