import 'package:flutter_test/flutter_test.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_engine.dart';
import 'package:fin_goal/features/scenarios/engine/scenario_input.dart';

void main() {
  late ScenarioEngine engine;

  setUp(() {
    engine = const ScenarioEngine();
  });

  group('ScenarioEngine.calculate()', () {
    test('basic case: 20tr income, 3tr saving, goal 100tr', () {
      final result = engine.calculate(ScenarioInput(
        currentSavings: 0,
        monthlySaving: 3000000,   // 3 triệu/tháng
        targetAmount: 100000000,  // 100 triệu
      ));

      // Expected: 100M / 3M = 34 tháng (ceil)
      expect(result.expectedMonths, 34);

      // Best case phải nhỏ hơn expected
      expect(result.bestCaseMonths, lessThan(result.expectedMonths));

      // Worst case phải lớn hơn expected
      expect(result.worstCaseMonths, greaterThan(result.expectedMonths));

      // Reliability bắt đầu ở 40% (chưa có data thực)
      expect(result.planReliability, 40.0);
    });

    test('user already has enough savings', () {
      final result = engine.calculate(ScenarioInput(
        currentSavings: 150000000, // 150 triệu
        monthlySaving: 3000000,
        targetAmount: 100000000,   // Goal: 100 triệu
      ));

      expect(result.expectedMonths, 0);
      expect(result.bestCaseMonths, 0);
      expect(result.worstCaseMonths, 0);
    });

    test('plan reliability increases with actual data', () {
      final noDataResult = engine.calculate(ScenarioInput(
        currentSavings: 0,
        monthlySaving: 3000000,
        targetAmount: 100000000,
        monthsWithActualData: 0,
      ));

      final threeMonthResult = engine.calculate(ScenarioInput(
        currentSavings: 9000000,   // 3 tháng × 3 triệu
        monthlySaving: 3000000,
        targetAmount: 100000000,
        monthsWithActualData: 3,
        averageVariance: 0.05,     // variance thấp → +10% bonus
      ));

      expect(threeMonthResult.planReliability,
          greaterThan(noDataResult.planReliability));
    });

    test('plan reliability never exceeds 95%', () {
      final result = engine.calculate(ScenarioInput(
        currentSavings: 0,
        monthlySaving: 3000000,
        targetAmount: 100000000,
        monthsWithActualData: 20, // 20 tháng data
        averageVariance: 0.01,    // rất consistent
      ));

      expect(result.planReliability, lessThanOrEqualTo(95.0));
    });

    test('what-if: buying iPhone 35tr delays goal', () {
      final input = ScenarioInput(
        currentSavings: 10000000,  // 10 triệu hiện có
        monthlySaving: 3000000,
        targetAmount: 100000000,
      );

      final delayMonths = engine.whatIfPurchaseImpact(
        input: input,
        purchaseCost: 35000000,   // Mua iPhone 35 triệu
      );

      // Phải làm chậm mục tiêu
      expect(delayMonths, greaterThan(0));

      // Delay khoảng 11-12 tháng (35M / 3M ≈ 11.7 tháng)
      expect(delayMonths, inInclusiveRange(10, 13));
    });
  });
}
