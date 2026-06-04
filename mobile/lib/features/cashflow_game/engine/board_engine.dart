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

const int fastTrackBoardSize = 24;
const List<BoardSpaceType> fastTrackBoard = [
  BoardSpaceType.fastTrackCashflowDay, // 0: Start
  BoardSpaceType.fastTrackBusiness,    // 1
  BoardSpaceType.fastTrackBusiness,    // 2
  BoardSpaceType.fastTrackDream,       // 3
  BoardSpaceType.fastTrackBusiness,    // 4
  BoardSpaceType.fastTrackBusiness,    // 5
  BoardSpaceType.fastTrackCashflowDay, // 6
  BoardSpaceType.fastTrackBusiness,    // 7
  BoardSpaceType.fastTrackBusiness,    // 8
  BoardSpaceType.fastTrackDream,       // 9
  BoardSpaceType.charity,              // 10
  BoardSpaceType.fastTrackBusiness,    // 11
  BoardSpaceType.fastTrackCashflowDay, // 12
  BoardSpaceType.fastTrackBusiness,    // 13
  BoardSpaceType.fastTrackBusiness,    // 14
  BoardSpaceType.fastTrackDream,       // 15
  BoardSpaceType.fastTrackBusiness,    // 16
  BoardSpaceType.fastTrackAudit,       // 17
  BoardSpaceType.fastTrackCashflowDay, // 18
  BoardSpaceType.fastTrackBusiness,    // 19
  BoardSpaceType.fastTrackBusiness,    // 20
  BoardSpaceType.fastTrackDream,       // 21
  BoardSpaceType.fastTrackBusiness,    // 22
  BoardSpaceType.fastTrackBusiness,    // 23
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

  MoveResult move(int currentPosition, int steps, {bool isFastTrack = false}) {
    int paychecks = 0;
    final board = isFastTrack ? fastTrackBoard : ratRaceBoard;
    final bSize = isFastTrack ? fastTrackBoardSize : boardSize;
    final paycheckType = isFastTrack ? BoardSpaceType.fastTrackCashflowDay : BoardSpaceType.paycheck;

    // Đếm số ô Paycheck đi ngang qua (không tính ô hiện tại)
    for (int i = 1; i <= steps; i++) {
      final pos = (currentPosition + i) % bSize;
      if (board[pos] == paycheckType) {
        paychecks++;
      }
    }

    final newPosition = (currentPosition + steps) % bSize;
    final landedSpace = board[newPosition];

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
      BoardSpaceType.fastTrackCashflowDay => '💸 Cashflow Day',
      BoardSpaceType.fastTrackBusiness => '🏢 Doanh Nghiệp',
      BoardSpaceType.fastTrackDream => '⭐ Ước Mơ',
      BoardSpaceType.fastTrackAudit => '⚖️ Thanh Tra',
    };
  }
}
