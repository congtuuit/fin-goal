import 'dart:math';

import 'package:fin_goal/features/cashflow/domain/entities/board_space.dart';
import 'package:fin_goal/features/cashflow/domain/entities/cashflow_state.dart';
import 'package:fin_goal/features/cashflow/domain/entities/game_scenario.dart';

class BoardMoveResult {
  final int newPosition;
  final SpaceType landedSpace;
  final bool crossedPaycheck;

  BoardMoveResult({
    required this.newPosition,
    required this.landedSpace,
    required this.crossedPaycheck,
  });
}

class BoardGameEngine {
  final _random = Random();

  /// Đổ xúc xắc 1-6
  int rollDice() {
    return _random.nextInt(6) + 1; // 1 to 6
  }

  /// Tính toán vị trí mới
  BoardMoveResult move(int currentPosition, int steps) {
    int newPosition = currentPosition + steps;
    bool crossedPaycheck = false;

    // Kích thước bàn cờ
    int boardSize = ratRaceBoard.length;

    // Đi qua vạch xuất phát hoặc đi qua ô Paycheck (bất kỳ ô nào là Paycheck)
    for (int i = 1; i <= steps; i++) {
      int stepPos = (currentPosition + i) % boardSize;
      if (ratRaceBoard[stepPos] == SpaceType.paycheck) {
        crossedPaycheck = true;
      }
    }

    newPosition = newPosition % boardSize;

    return BoardMoveResult(
      newPosition: newPosition,
      landedSpace: ratRaceBoard[newPosition],
      crossedPaycheck: crossedPaycheck,
    );
  }

  /// Bốc thẻ bài tự động cho các ô cố định (Doodad, Baby, Downsize, Charity)
  /// Opportunity và Market có thể dùng kho bài tĩnh hoặc AI.
  GameScenario? getScenarioForSpace(SpaceType space) {
    switch (space) {
      case SpaceType.doodad:
        return _getRandomDoodad();
      case SpaceType.baby:
        return _getBabyScenario();
      case SpaceType.downsize:
        return _getDownsizeScenario();
      case SpaceType.charity:
        return _getCharityScenario();
      case SpaceType.paycheck:
        return _getPaycheckScenario();
      case SpaceType.market:
        return _getRandomMarket();
      case SpaceType.opportunity:
        // Sẽ trả về null để CashflowProvider dùng AI Engine sinh thẻ Cơ hội
        return null; 
    }
  }

  GameScenario _getPaycheckScenario() {
    return const GameScenario(
      id: 'paycheck',
      title: 'Nhận Lương!',
      description: 'Tuyệt vời, bạn đã đi qua (hoặc dừng vào) ô Paycheck. Thu nhập hằng tháng đã được cộng vào tài khoản tiền mặt của bạn.',
      options: [
        GameOption(
          id: 'paycheck_ok',
          title: 'Tiếp tục',
          description: 'Nhận tiền và chờ lượt tiếp theo',
          aiFeedback: 'Tốt lắm, nhận lương là nguồn sống cơ bản của Rat Race.',
          impact: GameImpact(), // Cash was already added in provider
        )
      ],
    );
  }

  GameScenario _getBabyScenario() {
    return const GameScenario(
      id: 'baby',
      title: 'Chúc Mừng! Bạn Vừa Có Em Bé',
      description: 'Gia đình bạn vừa đón thêm thành viên mới. Chi phí sinh hoạt của bạn sẽ tăng lên!',
      options: [
        GameOption(
          id: 'baby_ok',
          title: 'Chấp nhận',
          description: 'Chi phí tăng thêm',
          aiFeedback: 'Con cái là niềm vui, nhưng cũng là một loại "tiêu sản" trong tài chính. Hãy tính toán lại chi tiêu nhé.',
          impact: GameImpact(), // Chi phí sẽ được tự động tăng trong CashflowProvider dựa theo số con
        )
      ],
    );
  }

  GameScenario _getDownsizeScenario() {
    return const GameScenario(
      id: 'downsize',
      title: 'Khủng Hoảng: Bạn Vừa Bị Sa Thải!',
      description: 'Công ty cắt giảm nhân sự. Bạn mất việc, mất 2 lượt chơi và phải thanh toán 1 khoản chi phí bằng tổng chi phí hằng tháng (để trang trải cuộc sống).',
      options: [
        GameOption(
          id: 'downsize_ok',
          title: 'Vượt qua',
          description: 'Chấp nhận thực tế',
          aiFeedback: 'Đây là rủi ro lớn nhất của người làm công ăn lương. Nếu bạn có nhiều thu nhập thụ động, mất việc không còn là vấn đề.',
          impact: GameImpact(), 
        )
      ],
    );
  }
  
  GameScenario _getCharityScenario() {
    return const GameScenario(
      id: 'charity',
      title: 'Từ Thiện',
      description: 'Bạn có muốn quyên góp 10% thu nhập hằng tháng của mình cho mục đích từ thiện không?',
      options: [
        GameOption(
          id: 'charity_yes',
          title: 'Quyên góp',
          description: 'Mất tiền nhưng được gieo phước (Vui lòng chọn vì game chưa hỗ trợ xúc xắc 2 viên)',
          aiFeedback: 'Cho đi là còn mãi. Một nhà đầu tư tốt luôn biết chia sẻ.',
          impact: GameImpact(),
        ),
        GameOption(
          id: 'charity_no',
          title: 'Bỏ qua',
          description: 'Giữ lại tiền mặt',
          aiFeedback: 'Bỏ qua cũng không sao, hãy tập trung vào mục tiêu của bạn.',
          impact: GameImpact(),
        )
      ],
    );
  }

  // --- Kho bài tĩnh ---
  GameScenario _getRandomDoodad() {
    final doodads = [
      GameScenario(
        id: 'doodad_1',
        title: 'Mua Điện Thoại Mới',
        description: 'Điện thoại của bạn bị hỏng, bạn phải mua iPhone mới trị giá 20 triệu VND.',
        options: [
          const GameOption(
            id: 'd1_buy',
            title: 'Thanh toán tiền mặt',
            description: 'Mất 20.000.000 VND',
            aiFeedback: 'Dùng tiền mặt mua tiêu sản làm giảm cơ hội đầu tư của bạn.',
            impact: GameImpact(cashChange: -20000000),
          )
        ],
      ),
      GameScenario(
        id: 'doodad_2',
        title: 'Sửa Nhà Mái Dột',
        description: 'Trận bão hôm qua làm mái nhà bạn bị dột, chi phí sửa chữa là 5 triệu VND.',
        options: [
          const GameOption(
            id: 'd2_pay',
            title: 'Thanh toán tiền mặt',
            description: 'Mất 5.000.000 VND',
            aiFeedback: 'Chi phí bất ngờ luôn có thể xảy ra. Hãy chuẩn bị quỹ khẩn cấp.',
            impact: GameImpact(cashChange: -5000000),
          )
        ],
      ),
      GameScenario(
        id: 'doodad_3',
        title: 'Mời Bạn Bè Ăn Tối',
        description: 'Sinh nhật bạn, bạn mời hội bạn thân ăn tối tiêu tốn 3 triệu VND.',
        options: [
          const GameOption(
            id: 'd3_pay',
            title: 'Thanh toán tiền mặt',
            description: 'Mất 3.000.000 VND',
            aiFeedback: 'Xây dựng mối quan hệ là tốt, nhưng hãy kiểm soát chi tiêu.',
            impact: GameImpact(cashChange: -3000000),
          )
        ],
      ),
    ];
    return doodads[_random.nextInt(doodads.length)];
  }

  GameScenario _getRandomMarket() {
    final markets = [
      GameScenario(
        id: 'market_1',
        title: 'Thị Trường Chứng Khoán Tăng Điểm',
        description: 'Có một đợt sóng mua cổ phiếu công nghệ. Những ai đang có cổ phiếu công nghệ có thể bán với giá cao.',
        options: [
          const GameOption(
            id: 'm1_ok',
            title: 'Tiếp tục',
            description: 'Vượt qua',
            aiFeedback: 'Nếu bạn có cổ phiếu, hãy cân nhắc chốt lời.',
            impact: GameImpact(),
          )
        ],
      ),
      GameScenario(
        id: 'market_2',
        title: 'Người Mua Đất Tìm Tới',
        description: 'Có người đang tìm mua đất ngoại ô với giá rất cao. Ai có bất động sản ngoại ô có thể bán ngay.',
        options: [
          const GameOption(
            id: 'm2_ok',
            title: 'Tiếp tục',
            description: 'Vượt qua',
            aiFeedback: 'Cơ hội tốt để thanh lý tài sản sinh lời kém để lấy tiền mặt tái đầu tư.',
            impact: GameImpact(),
          )
        ],
      ),
    ];
    return markets[_random.nextInt(markets.length)];
  }
}
