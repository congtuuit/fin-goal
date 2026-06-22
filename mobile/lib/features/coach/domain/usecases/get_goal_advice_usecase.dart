import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/coach/domain/entities/coach_advice.dart';
import 'package:fin_goal/features/coach/data/repositories/coach_repository.dart';
import 'package:fin_goal/core/services/ai_prompt_builder.dart';

/// Use case: Get AI coaching advice for a specific financial goal.
///
/// Thin orchestrator — delegates to [CoachRepository] which owns
/// the caching and ScenarioEngine pipeline.
class GetGoalAdviceUseCase {
  final CoachRepository _repository;

  const GetGoalAdviceUseCase({required CoachRepository repository})
      : _repository = repository;

  /// Returns [CoachAdvice] for the given [goal].
  ///
  /// [tone] controls the AI's communication style.
  /// [forceRefresh] bypasses cache and fetches fresh advice from AI.
  Future<CoachAdvice> call(
    Goal goal, {
    CoachTone tone = CoachTone.encouraging,
    bool forceRefresh = false,
  }) {
    return _repository.getGoalAdvice(goal, tone: tone, forceRefresh: forceRefresh);
  }
}
