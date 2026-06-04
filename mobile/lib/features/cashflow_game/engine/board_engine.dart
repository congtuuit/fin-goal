import 'dart:math';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';

/// Thuật toán di chuyển trên bàn cờ
const int boardSize = 24;

const List<BoardSpaceType> ratRaceBoard = [
  BoardSpaceType.paycheck,    // 0: Start
  BoardSpaceType.opportunity, // 1
  BoardSpaceType.doodad,      // 2
  BoardSpaceType.opportunity, // 3
  BoardSpaceType.charity,     // 4
  BoardSpaceType.opportunity, // 5
  BoardSpaceType.paycheck,    // 6
  BoardSpaceType.opportunity, // 7
  BoardSpaceType.market,      // 8
  BoardSpaceType.doodad,      // 9
  BoardSpaceType.opportunity, // 10
  BoardSpaceType.baby,        // 11
  BoardSpaceType.paycheck,    // 12
  BoardSpaceType.opportunity, // 13
  BoardSpaceType.doodad,      // 14
  BoardSpaceType.opportunity, // 15
  BoardSpaceType.market,      // 16
  BoardSpaceType.opportunity, // 17
  BoardSpaceType.paycheck,    // 18
  BoardSpaceType.opportunity, // 19
  BoardSpaceType.doodad,      // 20
  BoardSpaceType.opportunity, // 21
  BoardSpaceType.downsize,    // 22
  BoardSpaceType.opportunity, // 23
];

class MoveResult {
  final int newPosition;
  final int diceValue;
  final BoardSpaceType landedSpace;
  final bool crossedPaycheck;
  final int paychecksReceived; // số ô paycheck đi qua

  const MoveResult({
    required this.newPosition,
    required this.diceValue,
    required this.landedSpace,
    required this.crossedPaycheck,
    required this.paychecksReceived,
  });
}

class BoardEngine {
  final _random = Random();

  int rollDice() => _random.nextInt(6) + 1;

  MoveResult move(int currentPosition, int steps) {
    int paychecks = 0;

    // Đếm số ô Paycheck đi ngang qua (không tính ô hiện tại)
    for (int i = 1; i <= steps; i++) {
      final pos = (currentPosition + i) % boardSize;
      if (ratRaceBoard[pos] == BoardSpaceType.paycheck) {
        paychecks++;
      }
    }

    final newPosition = (currentPosition + steps) % boardSize;
    final landedSpace = ratRaceBoard[newPosition];

    return MoveResult(
      newPosition: newPosition,
      diceValue: steps,
      landedSpace: landedSpace,
      crossedPaycheck: paychecks > 0,
      paychecksReceived: paychecks,
    );
  }

  /// Tính giá tài sản theo thuật toán
  /// AssetPrice = BasePrice * MarketFactor * RandomFactor
  int calculateAssetPrice(int basePrice, double marketFactor) {
    final randomFactor = 0.95 + _random.nextDouble() * 0.10; // 0.95–1.05
    return (basePrice * marketFactor * randomFactor).round();
  }

  /// Ô Paycheck: Xúc xắc tự động nhận lương
  static String getSpaceLabel(BoardSpaceType type) {
    return switch (type) {
      BoardSpaceType.paycheck => '💰 Nhận Lương',
      BoardSpaceType.opportunity => '⭐ Cơ Hội',
      BoardSpaceType.doodad => '🛒 Tiêu Sản',
      BoardSpaceType.market => '📈 Thị Trường',
      BoardSpaceType.baby => '👶 Em Bé',
      BoardSpaceType.downsize => '❌ Mất Việc',
      BoardSpaceType.charity => '❤️ Từ Thiện',
    };
  }
}
