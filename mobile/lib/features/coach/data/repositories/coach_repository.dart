import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/coach/domain/entities/coach_advice.dart';
import 'package:fin_goal/core/services/ai_service.dart';
import 'package:fin_goal/core/services/ai_prompt_builder.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_engine.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Orchestrates AI coaching advice with smart caching.
///
/// Cache strategy:
/// - Key: `coach_advice_<goalId>_<yyyyMMdd>`
/// - TTL: 24 hours (per day, per goal)
/// - Invalidation: Auto on cache key change (new day) OR manual refresh.
///
/// Pipeline: Goal → ScenarioEngine → AiPromptBuilder → AiService → Cache → CoachAdvice
class CoachRepository {
  final AiService _aiService;
  final SharedPreferences _prefs;
  final ScenarioEngine _engine;
  final AiPromptBuilder _promptBuilder;

  static const _cachePrefix = 'coach_advice_';
  static const _cacheTimePrefix = 'coach_advice_time_';

  CoachRepository({
    required AiService aiService,
    required SharedPreferences prefs,
    ScenarioEngine engine = const ScenarioEngine(),
    AiPromptBuilder promptBuilder = const AiPromptBuilder(),
  })  : _aiService = aiService,
        _prefs = prefs,
        _engine = engine,
        _promptBuilder = promptBuilder;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Gets coaching advice for a goal.
  /// Returns cached advice if available and not expired.
  /// Pass [forceRefresh] = true to bypass cache.
  Future<CoachAdvice> getGoalAdvice(
    Goal goal, {
    CoachTone tone = CoachTone.encouraging,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cacheKey(goal.id);
    final timeKey = _cacheTimeKey(goal.id);

    // Try cache first
    if (!forceRefresh) {
      final cached = await _loadFromCache(goal.id, cacheKey, timeKey);
      if (cached != null) return cached;
    }

    // Cache miss → call AI
    final scenarioResult = _engine.calculate(ScenarioInput(
      currentSavings: goal.currentSavings,
      monthlySaving: goal.monthlySaving,
      targetAmount: goal.targetAmount,
    ));

    final prompt = _promptBuilder.buildGoalAdvicePrompt(
      goal: goal,
      result: scenarioResult,
      tone: tone,
    );

    final adviceText = await _aiService.chat(prompt);
    final now = DateTime.now();

    // Persist to cache
    await _prefs.setString(cacheKey, adviceText);
    await _prefs.setString(timeKey, now.toIso8601String());

    return CoachAdvice(
      goalId: goal.id,
      adviceText: adviceText,
      generatedAt: now,
      isFromCache: false,
    );
  }

  /// Clears cached advice for a specific goal.
  /// Should be called when user updates `currentSavings`.
  Future<void> invalidateCache(String goalId) async {
    await _prefs.remove(_cacheKey(goalId));
    await _prefs.remove(_cacheTimeKey(goalId));
  }

  /// Clears all coach advice cache entries.
  Future<void> clearAllCache() async {
    final keys = _prefs.getKeys().where(
          (k) => k.startsWith(_cachePrefix) || k.startsWith(_cacheTimePrefix),
        );
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _cacheKey(String goalId) => '$_cachePrefix${goalId}_${_todayKey()}';
  String _cacheTimeKey(String goalId) =>
      '$_cacheTimePrefix${goalId}_${_todayKey()}';

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  Future<CoachAdvice?> _loadFromCache(
    String goalId,
    String cacheKey,
    String timeKey,
  ) async {
    final cachedText = _prefs.getString(cacheKey);
    final cachedTimeStr = _prefs.getString(timeKey);

    if (cachedText == null || cachedTimeStr == null) return null;

    final cachedTime = DateTime.tryParse(cachedTimeStr);
    if (cachedTime == null) return null;

    final advice = CoachAdvice(
      goalId: goalId,
      adviceText: cachedText,
      generatedAt: cachedTime,
      isFromCache: true,
    );

    // Return cached if not expired (24h TTL)
    if (!advice.isExpired) return advice;

    // Expired — clean up
    await _prefs.remove(cacheKey);
    await _prefs.remove(timeKey);
    return null;
  }
}
