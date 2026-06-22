import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/core/services/ai_provider.dart';
import 'package:fin_goal/core/services/ai_prompt_builder.dart';
import 'package:fin_goal/features/coach/data/repositories/coach_repository.dart';
import 'package:fin_goal/features/coach/domain/entities/coach_advice.dart';
import 'package:fin_goal/features/coach/domain/usecases/get_goal_advice_usecase.dart';
import 'package:fin_goal/features/goals/domain/entities/goal.dart';

part 'coach_provider.g.dart';

// ── Repository Provider ────────────────────────────────────────────────────

@riverpod
CoachRepository coachRepository(Ref ref) {
  return CoachRepository(
    aiService: ref.watch(aiServiceProvider),
    prefs: getIt<SharedPreferences>(),
  );
}

// ── Use Case Provider ──────────────────────────────────────────────────────

@riverpod
GetGoalAdviceUseCase getGoalAdviceUseCase(Ref ref) {
  return GetGoalAdviceUseCase(
    repository: ref.watch(coachRepositoryProvider),
  );
}

// ── Per-Goal Coach Notifier ────────────────────────────────────────────────

/// State for a single goal's AI coaching advice.
@riverpod
class GoalCoachNotifier extends _$GoalCoachNotifier {
  @override
  FutureOr<CoachAdvice?> build(String goalId) async {
    // Don't auto-fetch; wait for explicit trigger.
    return null;
  }

  /// Fetches (or refreshes) coaching advice for the given [goal].
  Future<void> fetchAdvice(
    Goal goal, {
    CoachTone tone = CoachTone.encouraging,
    bool forceRefresh = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(getGoalAdviceUseCaseProvider)
          .call(goal, tone: tone, forceRefresh: forceRefresh),
    );
  }

  /// Invalidates cache and refreshes with a fresh AI call.
  Future<void> refresh(Goal goal, {CoachTone tone = CoachTone.encouraging}) {
    return fetchAdvice(goal, tone: tone, forceRefresh: true);
  }
}

// ── Coach Tone Setting Provider ────────────────────────────────────────────

/// Persists the user's preferred coach tone.
@riverpod
class CoachToneNotifier extends _$CoachToneNotifier {
  static const _prefKey = 'coach_tone';

  @override
  CoachTone build() {
    final prefs = getIt<SharedPreferences>();
    final saved = prefs.getString(_prefKey);
    return switch (saved) {
      'analytical' => CoachTone.analytical,
      'strict' => CoachTone.strict,
      _ => CoachTone.encouraging,
    };
  }

  Future<void> setTone(CoachTone tone) async {
    state = tone;
    final prefs = getIt<SharedPreferences>();
    await prefs.setString(_prefKey, tone.name);
  }
}
