/// Input data for the Scenario Calculation Engine.
/// Pure Dart — no Flutter or external dependencies.
class ScenarioInput {
  /// Current total savings (VND)
  final int currentSavings;

  /// Monthly amount user plans to save (VND)
  final int monthlySaving;

  /// Target amount to reach (VND)
  final int targetAmount;

  /// Annual inflation rate (default: 5% = 0.05)
  final double inflationRate;

  /// Variance buffer for best/worst case (default: ±15% = 0.15)
  final double varianceBuffer;

  /// Expected annual investment return (e.g. 0.08 for 8%)
  final double investmentReturn;

  /// Expected annual income growth (e.g. 0.05 for 5%)
  final double incomeGrowth;

  /// Number of months user has provided actual data (for reliability score)
  final int monthsWithActualData;

  /// Average variance from actual vs planned (0.0 = perfect, 1.0 = 100% off)
  final double averageVariance;

  const ScenarioInput({
    required this.currentSavings,
    required this.monthlySaving,
    required this.targetAmount,
    this.inflationRate = 0.05,
    this.varianceBuffer = 0.15,
    this.investmentReturn = 0.0,
    this.incomeGrowth = 0.0,
    this.monthsWithActualData = 0,
    this.averageVariance = 0.0,
  });
}
