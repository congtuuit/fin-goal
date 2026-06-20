import 'package:fin_goal/features/scenarios/engine/scenario_input.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_result.dart';

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

    final expected = _calculateMonths(input);
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
      investmentReturn: input.investmentReturn,
      incomeGrowth: input.incomeGrowth,
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
    final remaining = input.targetAmount - input.currentSavings;
    // No upper clamp — savings can go negative in what-if scenarios,
    // which correctly inflates remaining and shows the real impact.
    return remaining < 0 ? 0 : remaining;
  }

  /// Compound calculation loop.
  int _calculateMonths(ScenarioInput input) {
    if (input.monthlySaving <= 0) return 9999;

    double savings = input.currentSavings.toDouble();
    double target = input.targetAmount.toDouble();
    double currentMonthlySaving = input.monthlySaving.toDouble();
    
    int months = 0;
    while (savings < target && months < 1200) { // Cap at 100 years
      savings += currentMonthlySaving;
      
      if (input.investmentReturn > 0) {
        savings += savings * (input.investmentReturn / 12);
      }
      
      if (input.inflationRate > 0) {
        target += target * (input.inflationRate / 12);
      }
      
      if (months > 0 && months % 12 == 0) {
        if (input.incomeGrowth > 0) {
          currentMonthlySaving += currentMonthlySaving * input.incomeGrowth;
        }
      }
      
      months++;
    }
    
    return months;
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
