import 'scenario_input.dart';
import 'scenario_result.dart';

/// Core calculation engine for financial scenarios.
///
/// ⚠️  PURE DART — No Flutter, no external dependencies.
/// This class must remain 100% unit-testable without a Flutter environment.
///
/// Philosophy: We SIMULATE, not PREDICT.
/// All results must be framed as "based on the data you provided".
class ScenarioEngine {
  const ScenarioEngine();

  /// Main calculation entry point.
  ScenarioResult calculate(ScenarioInput input) {
    final remaining = _remainingAmount(input);
    if (remaining <= 0) {
      // User already has enough savings
      return ScenarioResult(
        bestCaseMonths: 0,
        expectedMonths: 0,
        worstCaseMonths: 0,
        planReliability: _planReliability(input),
        requiredMonthlySaving: 0,
        remainingAmount: 0,
      );
    }

    final expected = _expectedMonths(remaining, input.monthlySaving);
    final best = _bestCaseMonths(expected, input.varianceBuffer);
    final worst = _worstCaseMonths(expected, input.varianceBuffer);
    final reliability = _planReliability(input);

    return ScenarioResult(
      bestCaseMonths: best,
      expectedMonths: expected,
      worstCaseMonths: worst,
      planReliability: reliability,
      requiredMonthlySaving: input.monthlySaving,
      remainingAmount: remaining,
    );
  }

  /// Simulate the impact of a one-time purchase on the goal timeline.
  /// Returns how many ADDITIONAL months the goal will be delayed.
  int whatIfPurchaseImpact({
    required ScenarioInput input,
    required int purchaseCost,
  }) {
    // Without purchase
    final original = calculate(input);

    // With purchase (deducted from current savings)
    final modifiedInput = ScenarioInput(
      currentSavings: input.currentSavings - purchaseCost,
      monthlySaving: input.monthlySaving,
      targetAmount: input.targetAmount,
      inflationRate: input.inflationRate,
      varianceBuffer: input.varianceBuffer,
      monthsWithActualData: input.monthsWithActualData,
      averageVariance: input.averageVariance,
    );
    final withPurchase = calculate(modifiedInput);

    return withPurchase.expectedMonths - original.expectedMonths;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  int _remainingAmount(ScenarioInput input) {
    return (input.targetAmount - input.currentSavings).clamp(0, input.targetAmount);
  }

  /// Base case: straightforward division.
  /// Formula: ceil((target - savings) / monthly_saving)
  int _expectedMonths(int remaining, int monthlySaving) {
    if (monthlySaving <= 0) return 9999; // Guard: avoid division by zero
    return (remaining / monthlySaving).ceil();
  }

  /// Best case: user saves better than planned (buffer = 20% faster)
  int _bestCaseMonths(int expected, double varianceBuffer) {
    return (expected * (1.0 - varianceBuffer)).floor().clamp(1, expected);
  }

  /// Worst case: life events reduce savings (buffer = 30% slower)
  int _worstCaseMonths(int expected, double varianceBuffer) {
    return (expected * (1.0 + varianceBuffer * 2)).ceil();
  }

  /// Plan Reliability Score formula.
  ///
  /// Starts at 40% on first input.
  /// Increases as user provides actual monthly data.
  /// Max is 95% — we never claim 100% certainty.
  double _planReliability(ScenarioInput input) {
    double score = 40.0;

    // +5% per month of actual data provided
    score += input.monthsWithActualData * 5.0;

    // Bonus: variance < 10% means user is very consistent
    if (input.averageVariance < 0.10) score += 10.0;

    // Penalty: variance > 30% means life is unpredictable
    if (input.averageVariance > 0.30) score -= 5.0;

    // Cap at 95% — honest about uncertainty
    return score.clamp(0.0, 95.0);
  }
}
