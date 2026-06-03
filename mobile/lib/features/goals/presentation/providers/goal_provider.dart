import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/constants/app_config.dart';
import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:fin_goal/features/goals/data/repositories/local_goal_repository_impl.dart';
import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/goals/domain/repositories/goal_repository.dart';

part 'goal_provider.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────

@riverpod
GoalRepository goalRepository(Ref ref) {
  if (AppConfig.isOffline) {
    return LocalGoalRepositoryImpl(getIt<SharedPreferences>());
  }
  return GoalRepositoryImpl(Supabase.instance.client);
}

// ── Goals Controller ──────────────────────────────────────────────────────

sealed class GoalsState {
  const GoalsState();
}

class GoalsLoading extends GoalsState {
  const GoalsLoading();
}

class GoalsLoaded extends GoalsState {
  final List<Goal> goals;
  const GoalsLoaded(this.goals);
  
  Goal? get primaryGoal => goals.where((g) => g.isPrimary).firstOrNull ?? goals.firstOrNull;
}

class GoalsError extends GoalsState {
  final String message;
  const GoalsError(this.message);
}

@riverpod
class GoalsNotifier extends _$GoalsNotifier {
  @override
  GoalsState build() {
    _fetchGoals();
    return const GoalsLoading();
  }

  Future<void> _fetchGoals() async {
    final result = await ref.read(goalRepositoryProvider).getGoals();
    state = result.fold(
      (failure) => GoalsError(failure.message),
      (goals) => GoalsLoaded(goals),
    );
  }

  Future<Failure?> createGoal(Goal goal) async {
    final oldState = state;
    state = const GoalsLoading();
    
    final result = await ref.read(goalRepositoryProvider).createGoal(goal);
    return result.fold(
      (failure) {
        state = oldState; // revert
        return failure;
      },
      (newGoal) {
        if (oldState is GoalsLoaded) {
          final updatedOldGoals = newGoal.isPrimary
              ? oldState.goals.map((g) => g.copyWith(isPrimary: false)).toList()
              : oldState.goals;
          state = GoalsLoaded([...updatedOldGoals, newGoal]);
        } else {
          state = GoalsLoaded([newGoal]);
        }
        return null;
      },
    );
  }

  Future<Failure?> setPrimaryGoal(String goalId) async {
    final oldState = state;
    state = const GoalsLoading();
    
    final result = await ref.read(goalRepositoryProvider).setPrimaryGoal(goalId);
    return result.fold(
      (failure) {
        state = oldState; // revert
        return failure;
      },
      (_) {
        // Re-fetch all goals to get updated primary state
        _fetchGoals();
        return null;
      },
    );
  }

  Future<Failure?> updateGoal(Goal goal) async {
    final oldState = state;
    // Tạm thời hiển thị loading hoặc có thể optimistic UI update
    
    final result = await ref.read(goalRepositoryProvider).updateGoal(goal);
    return result.fold(
      (failure) {
        return failure;
      },
      (updatedGoal) {
        if (oldState is GoalsLoaded) {
          final updatedGoals = oldState.goals.map((g) {
            return g.id == updatedGoal.id ? updatedGoal : g;
          }).toList();
          state = GoalsLoaded(updatedGoals);
        }
        return null;
      },
    );
  }
}
