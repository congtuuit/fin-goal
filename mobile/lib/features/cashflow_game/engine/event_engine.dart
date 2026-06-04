import 'dart:math';
import 'package:fin_goal/core/utils/currency_formatter.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/game_state.dart';

// ── Model thẻ bài sự kiện ────────────────────────────────────────────────────
enum EventType { opportunity, doodad, market, baby, downsize, charity, paycheck }
enum DealSize { small, big } // Cho ô Opportunity

class EventCard {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final DealSize? dealSize;
  final List<EventChoice> choices;
  final double probability;

  const EventCard({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.dealSize,
    required this.choices,
    this.probability = 1.0,
  });
}

class EventChoice {
  final String id;
  final String label;
  final String shortDescription;
  final String teachingMoment; // Bài học tài chính
  final EventImpact impact;

  const EventChoice({
    required this.id,
    required this.label,
    required this.shortDescription,
    required this.teachingMoment,
    required this.impact,
  });
}

class EventImpact {
  final int cashChange;
  final int? newAssetPassiveIncome;
  final int? newAssetValue;
  final String? newAssetName;
  final AssetType? newAssetType;
  final int? downPayment;
  final int? mortgage;
  final int? monthlyMortgagePayment;
  final int? newLiabilityAmount;
  final int? newLiabilityMonthlyPayment;
  final String? newLiabilityName;
  final int creditScoreChange;
  final bool addChild;
  final int downsizeTurns;

  const EventImpact({
    this.cashChange = 0,
    this.newAssetPassiveIncome,
    this.newAssetValue,
    this.newAssetName,
    this.newAssetType,
    this.downPayment,
    this.mortgage,
    this.monthlyMortgagePayment,
    this.newLiabilityAmount,
    this.newLiabilityMonthlyPayment,
    this.newLiabilityName,
    this.creditScoreChange = 0,
    this.addChild = false,
    this.downsizeTurns = 0,
  });
}

// ── Event Engine ──────────────────────────────────────────────────────────────
class EventEngine {
  final _random = Random();

  /// Lấy thẻ bài phù hợp với loại ô và tình trạng tài chính
  EventCard? getEventCard(BoardSpaceType spaceType, GameState state, {bool positive = true}) {
    if (spaceType == BoardSpaceType.paycheck) {
      return _createPaycheckCard(state);
    }
    if (spaceType == BoardSpaceType.fastTrackCashflowDay) {
      return _createFastTrackCashflowDayCard(state);
    }
    final cards = _getCardsByType(spaceType, state, positive);
    if (cards.isEmpty) return null;
    return cards[_random.nextInt(cards.length)];
  }

  List<EventCard> _getCardsByType(BoardSpaceType type, GameState state, bool positive) {
    return switch (type) {
      BoardSpaceType.opportunity => positive ? _smallDeals : _bigDeals,
      BoardSpaceType.doodad => _doodads,
      BoardSpaceType.market => _marketEvents,
      BoardSpaceType.baby => [_babyCard],
      BoardSpaceType.downsize => [_downsizeCard],
      BoardSpaceType.charity => [_charityCard],
      BoardSpaceType.paycheck => [], // handled dynamically
      BoardSpaceType.fastTrackBusiness => _fastTrackBusinessEvents,
      BoardSpaceType.fastTrackDream => _fastTrackDreamEvents,
      BoardSpaceType.fastTrackAudit => _fastTrackAuditEvents,
      BoardSpaceType.fastTrackCashflowDay => [], // handled dynamically
    };
  }

  // ── Thẻ bài Paycheck ────────────────────────────────────────────────────────
  EventCard _createPaycheckCard(GameState state) {
    final amount = CurrencyFormatter.compact(state.monthlyCashflow);
    return EventCard(
      id: 'paycheck_receive',
      title: '💰 Nhận Lương Tháng!',
      description: 'Bạn vừa đi qua ô Nhận Lương!\n\nDòng tiền hàng tháng của bạn: $amount\n\n(Lưu ý: Số tiền này đã được hệ thống cộng tự động vào Tiền Mặt ngay khi bạn lăn xúc xắc ngang qua ô).',
      type: EventType.paycheck,
      choices: [
        EventChoice(
          id: 'paycheck_ok',
          label: 'Tuyệt Vời!',
          shortDescription: 'Đã nhận $amount',
          teachingMoment: 'Dòng tiền (Cashflow) = Tổng Thu Nhập - Tổng Chi Phí. Khi Dòng tiền lớn hơn 0, bạn sẽ ngày càng giàu có.',
          impact: const EventImpact(), // Không cộng lại tiền vì đã cộng ở Provider khi crossedPaycheck
        ),
      ],
    );
  }

  // ── Thẻ bài Cashflow Day (Fast Track) ───────────────────────────────────────
  EventCard _createFastTrackCashflowDayCard(GameState state) {
    final amount = CurrencyFormatter.compact(state.fastTrackIncome);
    return EventCard(
      id: 'ft_cashflow_day',
      title: '💸 CASHFLOW DAY!',
      description: 'Chúc mừng! Bạn vừa đi qua ô Cashflow Day.\n\nThu nhập của bạn: $amount\n\n(Tiền đã được cộng tự động vào Tiền Mặt).',
      type: EventType.paycheck,
      choices: [
        EventChoice(
          id: 'ft_cashflow_ok',
          label: 'Tuyệt Vời!',
          shortDescription: 'Đã nhận $amount',
          teachingMoment: 'Thu nhập trên Fast Track lớn hơn rất nhiều lần so với Rat Race. Tiền bây giờ tự động chảy vào túi bạn.',
          impact: const EventImpact(), 
        ),
      ],
    );
  }

  // ── Thẻ bài Baby ────────────────────────────────────────────────────────────
  static final EventCard _babyCard = EventCard(
    id: 'baby_born',
    title: '👶 Chào Đón Em Bé!',
    description: 'Gia đình bạn vừa có thêm thành viên mới. Hạnh phúc nhưng chi phí sinh hoạt sẽ tăng lên.',
    type: EventType.baby,
    choices: [
      EventChoice(
        id: 'baby_ok',
        label: 'Chào Đón Bé',
        shortDescription: 'Chi phí tăng thêm hàng tháng',
        teachingMoment: 'Con cái làm tăng chi phí hàng tháng. Đây là lý do "Cha Giàu" Kiyosaki nhấn mạnh tầm quan trọng của thu nhập thụ động trước khi lập gia đình.',
        impact: const EventImpact(addChild: true),
      ),
    ],
  );

  // ── Thẻ bài Downsize ────────────────────────────────────────────────────────
  static final EventCard _downsizeCard = EventCard(
    id: 'downsize_layoff',
    title: '❌ Bị Sa Thải!',
    description: 'Công ty cắt giảm nhân sự. Bạn mất việc, phải bỏ tiền trang trải 1 tháng và mất 2 lượt chơi.',
    type: EventType.downsize,
    choices: [
      EventChoice(
        id: 'downsize_ok',
        label: 'Vượt Qua',
        shortDescription: 'Mất 2 lượt + trừ chi phí tháng',
        teachingMoment: 'Rủi ro lớn nhất của người làm công ăn lương là mất việc. Khi thu nhập thụ động vượt chi phí, bạn không còn sợ bị sa thải nữa.',
        impact: const EventImpact(downsizeTurns: 2),
      ),
    ],
  );

  // ── Thẻ bài Charity ─────────────────────────────────────────────────────────
  static final EventCard _charityCard = EventCard(
    id: 'charity_donation',
    title: '❤️ Từ Thiện',
    description: 'Bạn có muốn quyên góp 10% thu nhập tháng này cho cộng đồng không? Những người từ thiện được xúc xắc thêm lần nữa trong vòng này.',
    type: EventType.charity,
    choices: [
      EventChoice(
        id: 'charity_yes',
        label: 'Quyên Góp',
        shortDescription: 'Mất 10% thu nhập tháng',
        teachingMoment: '"Cho đi là còn mãi." Nhiều nghiên cứu cho thấy người hay từ thiện có xu hướng giàu hơn về dài hạn.',
        impact: const EventImpact(), // tính trong provider
      ),
      EventChoice(
        id: 'charity_no',
        label: 'Bỏ Qua',
        shortDescription: 'Giữ lại toàn bộ tiền',
        teachingMoment: 'Bỏ qua cũng không sao, nhưng hãy nhớ: tư duy "cho đi" thường đi kèm với tư duy dư dả.',
        impact: const EventImpact(),
      ),
    ],
  );

  // ── Small Deals (Cơ hội nhỏ) ────────────────────────────────────────────────
  static final List<EventCard> _smallDeals = [
    EventCard(
      id: 'sd_apartment_rental',
      title: '🏠 Cơ Hội: Căn Hộ Cho Thuê',
      description: 'Một căn hộ 1 phòng ngủ đang rao bán với giá 350 triệu. Dòng tiền cho thuê ước tính 2.5 triệu/tháng sau khi trả góp.',
      type: EventType.opportunity,
      dealSize: DealSize.small,
      choices: [
        EventChoice(
          id: 'sd_apt_buy',
          label: 'Mua Căn Hộ',
          shortDescription: 'Đặt cọc 70 triệu, vay 280 triệu',
          teachingMoment: 'Bất động sản cho thuê tạo ra thu nhập thụ động đều đặn. Chìa khóa là dòng tiền dương sau khi trừ trả góp.',
          impact: EventImpact(
            cashChange: -70000000,
            newAssetName: 'Căn Hộ Cho Thuê',
            newAssetType: AssetType.realEstate,
            newAssetValue: 350000000,
            newAssetPassiveIncome: 2500000,
            downPayment: 70000000,
            mortgage: 280000000,
            monthlyMortgagePayment: 0,
          ),
        ),
        EventChoice(
          id: 'sd_apt_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Không đầu tư lần này',
          teachingMoment: 'Không mua cũng không sao. Chỉ mua khi bạn có đủ tiền đặt cọc và dòng tiền dương sau trả góp.',
          impact: const EventImpact(),
        ),
      ],
    ),

    EventCard(
      id: 'sd_gold_investment',
      title: '🥇 Cơ Hội: Vàng Giá Tốt',
      description: 'Giá vàng đang ở mức hấp dẫn. Mua 5 chỉ vàng với 25 triệu, có thể bán lời sau 1-2 năm.',
      type: EventType.opportunity,
      dealSize: DealSize.small,
      choices: [
        EventChoice(
          id: 'sd_gold_buy',
          label: 'Mua Vàng',
          shortDescription: 'Bỏ ra 25 triệu mua 5 chỉ',
          teachingMoment: 'Vàng là tài sản tích trữ giá trị, bảo vệ trước lạm phát. Tuy nhiên không tạo ra dòng tiền hàng tháng.',
          impact: EventImpact(
            cashChange: -25000000,
            newAssetName: '5 Chỉ Vàng',
            newAssetType: AssetType.other,
            newAssetValue: 25000000,
            newAssetPassiveIncome: 0,
          ),
        ),
        EventChoice(
          id: 'sd_gold_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Không đầu tư lần này',
          teachingMoment: 'Vàng tốt cho bảo tồn giá trị nhưng không tạo dòng tiền. Ưu tiên tài sản có thu nhập thụ động trước.',
          impact: const EventImpact(),
        ),
      ],
    ),

    EventCard(
      id: 'sd_stock_blue_chip',
      title: '📈 Cơ Hội: Cổ Phiếu Blue Chip',
      description: 'Cổ phiếu VNM đang ở vùng hỗ trợ tốt. Mua 100 cổ phiếu với 18 triệu, cổ tức dự kiến 1.5 triệu/năm.',
      type: EventType.opportunity,
      dealSize: DealSize.small,
      choices: [
        EventChoice(
          id: 'sd_stock_buy',
          label: 'Mua Cổ Phiếu',
          shortDescription: 'Mua 100 cổ = 18 triệu',
          teachingMoment: 'Cổ phiếu blue chip tạo ra thu nhập thụ động qua cổ tức và tăng giá trị dài hạn. Đây là cách người giàu đầu tư.',
          impact: EventImpact(
            cashChange: -18000000,
            newAssetName: '100 Cổ Phiếu VNM',
            newAssetType: AssetType.stock,
            newAssetValue: 18000000,
            newAssetPassiveIncome: 125000, // 1.5M/12 tháng
          ),
        ),
        EventChoice(
          id: 'sd_stock_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Không mua cổ phiếu',
          teachingMoment: 'Đầu tư cổ phiếu cần hiểu về công ty và thị trường. Bỏ qua nếu chưa sẵn sàng là quyết định thông minh.',
          impact: const EventImpact(),
        ),
      ],
    ),

    EventCard(
      id: 'sd_lottery_win',
      title: '🎰 May Mắn: Trúng Số Nhỏ',
      description: 'Bạn trúng giải khuyến khích của xổ số. Nhận được 5 triệu tiền mặt.',
      type: EventType.opportunity,
      dealSize: DealSize.small,
      choices: [
        EventChoice(
          id: 'sd_lottery_take',
          label: 'Nhận Tiền',
          shortDescription: '+5 triệu tiền mặt',
          teachingMoment: '"Cha Nghèo" tiêu tiền ngay khi nhận được. "Cha Giàu" dùng số tiền này để mua tài sản tạo ra thêm thu nhập.',
          impact: const EventImpact(cashChange: 5000000),
        ),
      ],
    ),

    EventCard(
      id: 'sd_freelance_project',
      title: '💼 Dự Án Freelance',
      description: 'Bạn có cơ hội nhận thêm dự án ngoài làm thêm thu nhập 8 triệu. Tuy nhiên sẽ mất nhiều thời gian hơn.',
      type: EventType.opportunity,
      dealSize: DealSize.small,
      choices: [
        EventChoice(
          id: 'sd_freelance_accept',
          label: 'Nhận Dự Án',
          shortDescription: '+8 triệu tiền mặt một lần',
          teachingMoment: 'Thu nhập chủ động từ freelance tốt nhưng không ổn định. Hãy dùng để tích lũy vốn đầu tư tài sản.',
          impact: const EventImpact(cashChange: 8000000),
        ),
        EventChoice(
          id: 'sd_freelance_reject',
          label: 'Từ Chối',
          shortDescription: 'Ưu tiên thời gian cho đầu tư',
          teachingMoment: 'Đôi khi từ chối công việc thêm là đúng khi bạn cần thời gian để nghiên cứu và quản lý đầu tư.',
          impact: const EventImpact(),
        ),
      ],
    ),
  ];

  // ── Big Deals (Cơ hội lớn) ──────────────────────────────────────────────────
  static final List<EventCard> _bigDeals = [
    EventCard(
      id: 'bd_commercial_property',
      title: '🏢 Cơ Hội Lớn: Nhà Phố Thương Mại',
      description: 'Một căn nhà phố thương mại đang bán dưới giá thị trường. Giá 1.5 tỷ, cho thuê kinh doanh 15 triệu/tháng sau trả góp.',
      type: EventType.opportunity,
      dealSize: DealSize.big,
      choices: [
        EventChoice(
          id: 'bd_commercial_buy',
          label: 'Mua Nhà Phố',
          shortDescription: 'Đặt cọc 300 triệu, vay 1.2 tỷ',
          teachingMoment: 'Nhà phố thương mại tạo ra dòng tiền cao nhất trong bất động sản. Đây là kiểu tài sản mà người giàu thường sở hữu.',
          impact: EventImpact(
            cashChange: -300000000,
            newAssetName: 'Nhà Phố Thương Mại',
            newAssetType: AssetType.realEstate,
            newAssetValue: 1500000000,
            newAssetPassiveIncome: 15000000,
            downPayment: 300000000,
            mortgage: 1200000000,
            monthlyMortgagePayment: 0,
          ),
        ),
        EventChoice(
          id: 'bd_commercial_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Chưa đủ vốn đặt cọc',
          teachingMoment: 'Không có đủ vốn thì bỏ qua là đúng. Hãy tiếp tục xây dựng dòng tiền từ Small Deals trước.',
          impact: const EventImpact(),
        ),
      ],
    ),

    EventCard(
      id: 'bd_startup_invest',
      title: '🚀 Cơ Hội Lớn: Đầu Tư Startup',
      description: 'Một startup công nghệ đang gọi vốn vòng Seed. Đầu tư 200 triệu để sở hữu 5% cổ phần. Rủi ro cao nhưng tiềm năng cực lớn.',
      type: EventType.opportunity,
      dealSize: DealSize.big,
      choices: [
        EventChoice(
          id: 'bd_startup_invest',
          label: 'Đầu Tư 200 Triệu',
          shortDescription: 'Rủi ro cao, tiềm năng x10',
          teachingMoment: 'Đầu tư startup rất rủi ro (>90% thất bại) nhưng nếu thành công có thể thay đổi cuộc đời. Chỉ đầu tư số tiền bạn chấp nhận mất.',
          impact: EventImpact(
            cashChange: -200000000,
            newAssetName: '5% Cổ Phần Startup XYZ',
            newAssetType: AssetType.business,
            newAssetValue: 200000000,
            newAssetPassiveIncome: 0,
          ),
        ),
        EventChoice(
          id: 'bd_startup_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Quá rủi ro',
          teachingMoment: 'Đây là quyết định thận trọng và hoàn toàn hợp lý. Không phải ai cũng phù hợp với đầu tư mạo hiểm.',
          impact: const EventImpact(),
        ),
      ],
    ),
  ];

  // ── Doodads (Tiêu sản bất ngờ) ──────────────────────────────────────────────
  static final List<EventCard> _doodads = [
    EventCard(
      id: 'dd_car_repair',
      title: '🔧 Xe Hỏng Đột Xuất',
      description: 'Xe của bạn bị hỏng động cơ cần sửa gấp. Chi phí sửa chữa 8 triệu.',
      type: EventType.doodad,
      choices: [
        EventChoice(
          id: 'dd_car_pay',
          label: 'Sửa Xe',
          shortDescription: '-8 triệu tiền mặt',
          teachingMoment: 'Chi phí bất ngờ là thực tế của cuộc sống. Quỹ khẩn cấp (3-6 tháng chi phí) giúp bạn xử lý những tình huống này mà không bị ảnh hưởng kế hoạch đầu tư.',
          impact: const EventImpact(cashChange: -8000000),
        ),
      ],
    ),

    EventCard(
      id: 'dd_new_phone',
      title: '📱 Điện Thoại Mới Ra Mắt',
      description: 'iPhone mới vừa ra mắt, bạn cảm thấy điện thoại cũ đã lỗi thời và quyết định mua. Chi phí 22 triệu.',
      type: EventType.doodad,
      choices: [
        EventChoice(
          id: 'dd_phone_buy',
          label: 'Mua Điện Thoại',
          shortDescription: '-22 triệu tiền mặt',
          teachingMoment: '"Cha Nghèo" mua những thứ họ muốn ngay lập tức. "Cha Giàu" hỏi: "Khoản mua này có tạo ra tiền không?" — Điện thoại là tiêu sản, không tạo ra dòng tiền.',
          impact: const EventImpact(cashChange: -22000000),
        ),
        EventChoice(
          id: 'dd_phone_skip',
          label: 'Dùng Máy Cũ',
          shortDescription: 'Giữ tiền để đầu tư',
          teachingMoment: 'Xuất sắc! Giữ lại 22 triệu để đầu tư vào tài sản có thể tạo ra dòng tiền thụ động.',
          impact: const EventImpact(),
        ),
      ],
    ),

    EventCard(
      id: 'dd_vacation',
      title: '✈️ Kỳ Nghỉ Du Lịch',
      description: 'Bạn bè rủ đi du lịch Đà Nẵng cuối tuần. Chi phí tổng cộng 5 triệu.',
      type: EventType.doodad,
      choices: [
        EventChoice(
          id: 'dd_vacation_go',
          label: 'Đi Du Lịch',
          shortDescription: '-5 triệu tiền mặt',
          teachingMoment: 'Trải nghiệm sống quan trọng, nhưng hãy ngân sách cho nó. Lập kế hoạch du lịch thay vì chi tiêu bốc đồng.',
          impact: const EventImpact(cashChange: -5000000),
        ),
        EventChoice(
          id: 'dd_vacation_skip',
          label: 'Ở Nhà',
          shortDescription: 'Tiết kiệm 5 triệu',
          teachingMoment: 'Đôi khi cần từ chối để đạt mục tiêu tài chính. Hãy xây dựng "Quỹ Du Lịch" riêng để không ảnh hưởng kế hoạch đầu tư.',
          impact: const EventImpact(),
        ),
      ],
    ),

    EventCard(
      id: 'dd_roof_repair',
      title: '🏠 Mái Nhà Bị Dột',
      description: 'Trận bão vừa rồi làm mái nhà bị hư hại. Chi phí sửa chữa 12 triệu.',
      type: EventType.doodad,
      choices: [
        EventChoice(
          id: 'dd_roof_fix',
          label: 'Sửa Ngay',
          shortDescription: '-12 triệu tiền mặt',
          teachingMoment: 'Chi phí nhà cửa là không thể tránh. Đây là lý do "Cha Giàu" không coi nhà ở là tài sản — nó tiêu tốn tiền thay vì tạo ra tiền.',
          impact: const EventImpact(cashChange: -12000000),
        ),
      ],
    ),

    EventCard(
      id: 'dd_hospital',
      title: '🏥 Chi Phí Y Tế',
      description: 'Bạn bị ốm và cần nhập viện điều trị. Chi phí viện phí sau bảo hiểm là 15 triệu.',
      type: EventType.doodad,
      choices: [
        EventChoice(
          id: 'dd_hospital_pay',
          label: 'Chi Trả',
          shortDescription: '-15 triệu tiền mặt',
          teachingMoment: 'Sức khỏe là tài sản quý giá nhất. Bảo hiểm sức khỏe toàn diện và quỹ khẩn cấp là 2 lá chắn quan trọng nhất.',
          impact: const EventImpact(cashChange: -15000000),
        ),
      ],
    ),
  ];

  // ── Market Events ────────────────────────────────────────────────────────────
  static final List<EventCard> _marketEvents = [
    EventCard(
      id: 'mk_real_estate_boom',
      title: '🏠 Bất Động Sản Tăng Giá',
      description: 'Thị trường bất động sản đang sốt. Ai đang có bất động sản có thể bán lời ngay bây giờ với giá cao hơn 20%.',
      type: EventType.market,
      choices: [
        EventChoice(
          id: 'mk_realestate_ok',
          label: 'Tiếp Tục',
          shortDescription: 'Tài sản BĐS tăng giá 20%',
          teachingMoment: 'Thị trường bất động sản có chu kỳ. Người giàu thường mua khi thị trường trầm lắng và bán khi thị trường sốt nóng.',
          impact: const EventImpact(), // tính trong provider
        ),
      ],
    ),

    EventCard(
      id: 'mk_stock_crash',
      title: '📉 Cổ Phiếu Sụt Giảm',
      description: 'Thị trường chứng khoán đang điều chỉnh mạnh. Giá cổ phiếu giảm 15-30%. Cơ hội mua thêm với giá tốt!',
      type: EventType.market,
      choices: [
        EventChoice(
          id: 'mk_stock_crash_ok',
          label: 'Tiếp Tục',
          shortDescription: 'Cổ phiếu giảm 20%',
          teachingMoment: 'Warren Buffett nói: "Hãy tham lam khi người khác sợ hãi." Khi thị trường sụt giảm là cơ hội mua tài sản tốt với giá rẻ.',
          impact: const EventImpact(),
        ),
      ],
    ),
  ];

  // ── Fast Track: Business ────────────────────────────────────────────────────
  static final List<EventCard> _fastTrackBusinessEvents = [
    EventCard(
      id: 'ft_bus_software',
      title: '🏢 Công Ty Phần Mềm',
      description: 'Một công ty phần mềm đang cần vốn. Mua lại với giá 3 tỷ VNĐ, đem lại dòng tiền 40 triệu VNĐ/tháng.',
      type: EventType.opportunity,
      choices: [
        EventChoice(
          id: 'ft_bus_software_buy',
          label: 'Mua Công Ty',
          shortDescription: '-3 Tỷ, +40 Triệu/tháng',
          teachingMoment: 'Lợi nhuận giảm do ngành công nghệ cạnh tranh gay gắt. Bạn cần tích lũy doanh nghiệp này nhiều hơn.',
          impact: EventImpact(
            cashChange: -3000000000,
            newAssetName: 'Công Ty Phần Mềm',
            newAssetType: AssetType.business,
            newAssetValue: 3000000000,
            newAssetPassiveIncome: 40000000,
          ),
        ),
        EventChoice(
          id: 'ft_bus_software_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Giữ lại tiền',
          teachingMoment: 'Biết nói không với những cơ hội có tỷ suất lợi nhuận (ROI) thấp là một kỹ năng quan trọng.',
          impact: const EventImpact(),
        ),
      ],
    ),
    EventCard(
      id: 'ft_bus_franchise',
      title: '🏢 Nhượng Quyền Cà Phê',
      description: 'Cơ hội mua chuỗi nhượng quyền cà phê nổi tiếng. Giá mua 8 tỷ VNĐ, lợi nhuận 90 triệu VNĐ/tháng.',
      type: EventType.opportunity,
      choices: [
        EventChoice(
          id: 'ft_bus_franchise_buy',
          label: 'Mua Chuỗi',
          shortDescription: '-8 Tỷ, +90 Triệu/tháng',
          teachingMoment: 'Mô hình nhượng quyền an toàn nhưng lợi nhuận không cao vì phải chia sẻ doanh thu cho công ty mẹ.',
          impact: EventImpact(
            cashChange: -8000000000,
            newAssetName: 'Chuỗi Cà Phê',
            newAssetType: AssetType.business,
            newAssetValue: 8000000000,
            newAssetPassiveIncome: 90000000,
          ),
        ),
        EventChoice(
          id: 'ft_bus_franchise_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Không mua',
          teachingMoment: 'Chờ đợi những thương vụ có tỷ suất lợi nhuận cao hơn.',
          impact: const EventImpact(),
        ),
      ],
    ),
    EventCard(
      id: 'ft_bus_hotel',
      title: '🏨 Chuỗi Khách Sạn Cao Cấp',
      description: 'Mua lại chuỗi khách sạn nghỉ dưỡng hạng sang. Cần số vốn khổng lồ: 30 tỷ VNĐ. Dòng tiền: 350 triệu VNĐ/tháng.',
      type: EventType.opportunity,
      choices: [
        EventChoice(
          id: 'ft_bus_hotel_buy',
          label: 'Đầu Tư Khách Sạn',
          shortDescription: '-30 Tỷ, +350 Triệu/tháng',
          teachingMoment: 'Bất động sản thương mại cao cấp mang lại dòng tiền ổn định khổng lồ, nhưng yêu cầu vốn vào cực lớn.',
          impact: EventImpact(
            cashChange: -30000000000,
            newAssetName: 'Chuỗi Khách Sạn Cao Cấp',
            newAssetType: AssetType.realEstate,
            newAssetValue: 30000000000,
            newAssetPassiveIncome: 350000000,
          ),
        ),
        EventChoice(
          id: 'ft_bus_hotel_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Không đủ vốn',
          teachingMoment: 'Hãy tiếp tục đi qua các ô Cashflow Day để tích lũy hàng chục tỷ tiền mặt trước khi chơi ván bài lớn.',
          impact: const EventImpact(),
        ),
      ],
    ),
    EventCard(
      id: 'ft_bus_commercial_re',
      title: '🏢 Tòa Nhà Văn Phòng Hạng A',
      description: 'Sở hữu ngay tòa tháp văn phòng trung tâm. Giá trị thương vụ: 50 tỷ VNĐ, dòng tiền 600 triệu VNĐ/tháng.',
      type: EventType.opportunity,
      choices: [
        EventChoice(
          id: 'ft_bus_cre_buy',
          label: 'Mua Tòa Tháp',
          shortDescription: '-50 Tỷ, +600 Triệu/tháng',
          teachingMoment: 'Đây là cuộc chơi của những nhà phiệt tài chính. Những thương vụ này đẩy nhanh tốc độ chiến thắng cực nhanh.',
          impact: EventImpact(
            cashChange: -50000000000,
            newAssetName: 'Tòa Tháp Văn Phòng',
            newAssetType: AssetType.realEstate,
            newAssetValue: 50000000000,
            newAssetPassiveIncome: 600000000,
          ),
        ),
        EventChoice(
          id: 'ft_bus_cre_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Tránh đọng vốn',
          teachingMoment: 'Nếu bạn có 50 Tỷ, một quyết định sai lầm có thể giết chết thanh khoản. Nhưng trong Fast Track, tiền đẻ ra tiền rất nhanh.',
          impact: const EventImpact(),
        ),
      ],
    ),
    EventCard(
      id: 'ft_bus_green_energy',
      title: '⚡ Đầu Tư Năng Lượng Xanh',
      description: 'Góp vốn 15 tỷ VNĐ vào nhà máy điện mặt trời. Dòng tiền dài hạn: 150 triệu VNĐ/tháng.',
      type: EventType.opportunity,
      choices: [
        EventChoice(
          id: 'ft_bus_energy_buy',
          label: 'Góp Vốn',
          shortDescription: '-15 Tỷ, +150 Triệu/tháng',
          teachingMoment: 'Đầu tư cơ sở hạ tầng mang tính bền vững nhưng thu hồi vốn lâu hơn.',
          impact: EventImpact(
            cashChange: -15000000000,
            newAssetName: 'Điện Mặt Trời',
            newAssetType: AssetType.business,
            newAssetValue: 15000000000,
            newAssetPassiveIncome: 150000000,
          ),
        ),
        EventChoice(
          id: 'ft_bus_energy_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Thương vụ khác tốt hơn',
          teachingMoment: 'Đầu tư bền vững là tốt, nhưng nếu ưu tiên tối đa hóa lợi nhuận tài chính, có thể có lựa chọn tốt hơn.',
          impact: const EventImpact(),
        ),
      ],
    ),
    EventCard(
      id: 'ft_risk_lawsuit',
      title: '⚖️ Kiện Cáo Sở Hữu Trí Tuệ',
      description: 'Công ty đối thủ kiện bạn vi phạm bản quyền. Mặc dù vô lý, nhưng bạn phải tốn 2 Tỷ VNĐ chi phí luật sư để dàn xếp ngoài tòa.',
      type: EventType.doodad,
      choices: [
        EventChoice(
          id: 'ft_risk_lawsuit_pay',
          label: 'Dàn Xếp (Nộp Phạt)',
          shortDescription: '-2 Tỷ Tiền Mặt',
          teachingMoment: 'Khi bạn giàu có trên Fast Track, bạn trở thành mục tiêu của các vụ kiện cáo. Sự giàu có luôn đi kèm với chi phí bảo vệ tài sản.',
          impact: const EventImpact(cashChange: -2000000000),
        ),
      ],
    ),
    EventCard(
      id: 'ft_risk_crisis',
      title: '📉 Khủng Hoảng Cục Bộ',
      description: 'Ngành nghề kinh doanh cốt lõi của bạn gặp khủng hoảng. Bạn phải bơm 5 Tỷ VNĐ tiền mặt để cứu hệ thống, nếu không doanh nghiệp sẽ sụp đổ.',
      type: EventType.doodad,
      choices: [
        EventChoice(
          id: 'ft_risk_crisis_pay',
          label: 'Bơm Vốn Cứu Nguy',
          shortDescription: '-5 Tỷ Tiền Mặt',
          teachingMoment: 'Kinh doanh luôn tiềm ẩn rủi ro thị trường. Luôn giữ một khoản tiền mặt dự phòng (thanh khoản) là bài học sống còn.',
          impact: const EventImpact(cashChange: -5000000000),
        ),
      ],
    ),
  ];

  // ── Fast Track: Dream ───────────────────────────────────────────────────────
  static final List<EventCard> _fastTrackDreamEvents = [
    EventCard(
      id: 'ft_dream_island',
      title: '⭐ Mua Hòn Đảo Riêng',
      description: 'Bạn đã tìm thấy hòn đảo nhiệt đới trong mơ của mình. Giá: 1,000,000 USD (20 tỷ VNĐ). Nếu đây là ước mơ bạn đã chọn từ đầu, BẠN SẼ THẮNG TRÒ CHƠI NẾU MUA!',
      type: EventType.opportunity,
      choices: [
        EventChoice(
          id: 'ft_dream_buy',
          label: 'Thực Hiện Ước Mơ',
          shortDescription: '-20 Tỷ VNĐ',
          teachingMoment: 'Tiền bạc chỉ là công cụ. Mục đích cuối cùng là thực hiện được ước mơ và sống cuộc đời bạn mong muốn.',
          impact: EventImpact(
            cashChange: -20000000000, // 20 billion
            newAssetName: 'Dream: Đảo Riêng', // To trigger win condition if matches Dream ID
            newAssetType: AssetType.other,
            newAssetValue: 20000000000,
          ),
        ),
        EventChoice(
          id: 'ft_dream_skip',
          label: 'Bỏ Qua',
          shortDescription: 'Chưa đủ tiền / Không phải ước mơ',
          teachingMoment: 'Chỉ mua nếu bạn có đủ tiền và đây đúng là mục tiêu tối thượng của bạn.',
          impact: const EventImpact(),
        ),
      ],
    ),
  ];

  // ── Fast Track: Audit ───────────────────────────────────────────────────────
  static final List<EventCard> _fastTrackAuditEvents = [
    EventCard(
      id: 'ft_audit_tax',
      title: '⚖️ Thanh Tra Thuế',
      description: 'Cơ quan thuế tiến hành kiểm toán doanh nghiệp của bạn. Bạn phải nộp phạt và chi phí pháp lý bằng 50% số Tiền Mặt hiện có!',
      type: EventType.doodad,
      choices: [
        EventChoice(
          id: 'ft_audit_pay',
          label: 'Nộp Phạt',
          shortDescription: '-50% Tiền Mặt',
          teachingMoment: 'Càng giàu có, bạn càng cần đội ngũ cố vấn tài chính và luật sư giỏi để bảo vệ tài sản hợp pháp.',
          impact: const EventImpact(), // handled in game_provider.dart
        ),
      ],
    ),
  ];
}
