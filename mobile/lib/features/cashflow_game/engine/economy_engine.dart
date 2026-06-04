import 'dart:math';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';

/// Markov Chain kinh tế — Mô phỏng chu kỳ kinh tế thực tế
class EconomyEngine {
  final _random = Random();

  /// Xác suất chuyển trạng thái (Markov Chain)
  /// [currentState] → {nextState: probability}
  static const Map<EconomyState, Map<EconomyState, double>> _transitions = {
    EconomyState.growth: {
      EconomyState.growth: 0.70,
      EconomyState.normal: 0.25,
      EconomyState.recession: 0.05,
    },
    EconomyState.normal: {
      EconomyState.growth: 0.10,
      EconomyState.normal: 0.65,
      EconomyState.recession: 0.20,
      EconomyState.crisis: 0.05,
    },
    EconomyState.recession: {
      EconomyState.normal: 0.30,
      EconomyState.recession: 0.50,
      EconomyState.crisis: 0.20,
    },
    EconomyState.crisis: {
      EconomyState.crisis: 0.40,
      EconomyState.recovery: 0.60,
    },
    EconomyState.recovery: {
      EconomyState.recovery: 0.30,
      EconomyState.normal: 0.50,
      EconomyState.growth: 0.20,
    },
  };

  /// Hệ số ảnh hưởng của kinh tế đến giá tài sản
  static const Map<EconomyState, double> _assetMultiplier = {
    EconomyState.growth: 1.15,
    EconomyState.normal: 1.0,
    EconomyState.recession: 0.85,
    EconomyState.crisis: 0.65,
    EconomyState.recovery: 0.95,
  };

  /// Hệ số xác suất gặp sự kiện tích cực
  static const Map<EconomyState, double> _positiveEventBias = {
    EconomyState.growth: 0.65,
    EconomyState.normal: 0.50,
    EconomyState.recession: 0.35,
    EconomyState.crisis: 0.20,
    EconomyState.recovery: 0.45,
  };

  /// Tỉ lệ lạm phát theo trạng thái kinh tế
  static const Map<EconomyState, (double min, double max)> _inflationRange = {
    EconomyState.growth: (0.04, 0.08),
    EconomyState.normal: (0.02, 0.05),
    EconomyState.recession: (0.01, 0.04),
    EconomyState.crisis: (0.08, 0.15),
    EconomyState.recovery: (0.03, 0.07),
  };

  /// Chuyển trạng thái kinh tế theo Markov Chain
  EconomyState nextEconomyState(EconomyState current) {
    final transitions = _transitions[current]!;
    double roll = _random.nextDouble();
    double cumulative = 0.0;

    for (final entry in transitions.entries) {
      cumulative += entry.value;
      if (roll <= cumulative) return entry.key;
    }
    return current; // fallback
  }

  /// Lấy hệ số giá tài sản theo kinh tế
  double getAssetMultiplier(EconomyState state) =>
      _assetMultiplier[state] ?? 1.0;

  /// Lấy xác suất sự kiện tích cực
  double getPositiveEventBias(EconomyState state) =>
      _positiveEventBias[state] ?? 0.5;

  /// Tính tỉ lệ lạm phát ngẫu nhiên cho trạng thái hiện tại
  double getInflationRate(EconomyState state) {
    final range = _inflationRange[state] ?? (0.02, 0.05);
    return range.$1 + _random.nextDouble() * (range.$2 - range.$1);
  }

  /// Tên hiển thị của trạng thái kinh tế
  static String getStateName(EconomyState state) {
    return switch (state) {
      EconomyState.growth => '📈 Tăng Trưởng',
      EconomyState.normal => '📊 Bình Thường',
      EconomyState.recession => '📉 Suy Thoái',
      EconomyState.crisis => '🔴 Khủng Hoảng',
      EconomyState.recovery => '🔄 Phục Hồi',
    };
  }
}
