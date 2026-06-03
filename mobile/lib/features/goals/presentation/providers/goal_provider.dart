import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';

part 'goal_provider.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────

@riverpod
GoalRepository goalRepository(Ref ref) {
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
          state = GoalsLoaded([...oldState.goals, newGoal]);
        } else {
          state = GoalsLoaded([newGoal]);
        }
        return null;
      },
    );
  }
}
