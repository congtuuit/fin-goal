/// Output result from the Scenario Calculation Engine.
/// Represents the three financial scenarios: best, expected, worst.
class ScenarioResult {
  /// Optimistic scenario — saving goes better than planned (months)
  final int bestCaseMonths;

  /// Base scenario — everything goes as planned (months)
  final int expectedMonths;

  /// Pessimistic scenario — life events reduce savings (months)
  final int worstCaseMonths;

  /// Plan reliability score (0–95%).
  /// Increases as more real data is provided.
  /// Never reaches 100% — we are honest about uncertainty.
  final double planReliability;

  /// Monthly saving needed to hit the goal in expectedMonths (VND)
  final int requiredMonthlySaving;

  /// Amount still needed after current savings (VND)
  final int remainingAmount;

  const ScenarioResult({
    required this.bestCaseMonths,
    required this.expectedMonths,
    required this.worstCaseMonths,
    required this.planReliability,
    required this.requiredMonthlySaving,
    required this.remainingAmount,
  });
}
