import 'package:equatable/equatable.dart';
import 'package:fin_goal/features/cashflow_game/domain/entities/occupation.dart';

// ── Loại ô trên bàn cờ ──────────────────────────────────────────────────────
enum BoardSpaceType {
  paycheck,    // Nhận lương
  opportunity, // Cơ hội đầu tư (Small/Big Deal)
  doodad,      // Tiêu sản bất ngờ
  market,      // Thị trường (tác động giá tài sản)
  baby,        // Sinh con (tăng chi phí)
  downsize,    // Thất nghiệp (mất lượt)
  charity,     // Từ thiện
}

// ── Trạng thái kinh tế ──────────────────────────────────────────────────────
enum EconomyState { growth, normal, recession, crisis, recovery }

// ── Tài sản ─────────────────────────────────────────────────────────────────
enum AssetType { realEstate, stock, business, bond, other }

class Asset extends Equatable {
  final String id;
  final String name;
  final AssetType type;
  final int purchasePrice;
  final int currentValue;
  final int monthlyPassiveIncome; // Dòng tiền thụ động hàng tháng
  final int downPayment;          // Tiền đặt cọc (nếu vay)
  final int mortgage;             // Nợ vay (nếu có)
  final int monthlyMortgagePayment;

  const Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.purchasePrice,
    required this.currentValue,
    required this.monthlyPassiveIncome,
    this.downPayment = 0,
    this.mortgage = 0,
    this.monthlyMortgagePayment = 0,
  });

  @override
  List<Object?> get props => [id];

  Asset copyWith({int? currentValue, int? monthlyPassiveIncome}) => Asset(
        id: id,
        name: name,
        type: type,
        purchasePrice: purchasePrice,
        currentValue: currentValue ?? this.currentValue,
        monthlyPassiveIncome:
            monthlyPassiveIncome ?? this.monthlyPassiveIncome,
        downPayment: downPayment,
        mortgage: mortgage,
        monthlyMortgagePayment: monthlyMortgagePayment,
      );
}

// ── Tiêu sản ─────────────────────────────────────────────────────────────────
class Liability extends Equatable {
  final String id;
  final String name;
  final int totalOwed;
  final int monthlyPayment;

  const Liability({
    required this.id,
    required this.name,
    required this.totalOwed,
    required this.monthlyPayment,
  });

  @override
  List<Object?> get props => [id];
}

// ── Game State chính ─────────────────────────────────────────────────────────
class GameState extends Equatable {
  final String playerId;
  final Occupation occupation;

  // Vị trí & lượt đi
  final int boardPosition;   // 0–23
  final int currentTurn;     // số lượt đã chơi
  final int downsizeTurns;   // số lượt bị thất nghiệp

  // Tài chính
  final int cashOnHand;
  final int monthlyIncome;   // lương + thu nhập thụ động
  final int monthlyExpenses; // sinh hoạt + trả nợ + con
  final int children;        // số con (mỗi con tăng 10% livingCost)
  final int creditScore;

  // Tài sản & Nợ
  final List<Asset> assets;
  final List<Liability> liabilities;

  // Kinh tế & XP
  final EconomyState economyState;
  final double inflationRate;  // 0.02 – 0.12
  final int xp;
  final int level;

  const GameState({
    required this.playerId,
    required this.occupation,
    this.boardPosition = 0,
    this.currentTurn = 0,
    this.downsizeTurns = 0,
    required this.cashOnHand,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    this.children = 0,
    required this.creditScore,
    this.assets = const [],
    this.liabilities = const [],
    this.economyState = EconomyState.normal,
    this.inflationRate = 0.03,
    this.xp = 0,
    this.level = 1,
  });

  // ── Getters ────────────────────────────────────────────────────────────────

  int get passiveIncome =>
      assets.fold(0, (sum, a) => sum + a.monthlyPassiveIncome);

  int get totalMonthlyIncome => occupation.monthlySalary + passiveIncome;

  int get totalLiabilityPayment =>
      liabilities.fold(0, (sum, l) => sum + l.monthlyPayment) +
      assets.fold(0, (sum, a) => sum + a.monthlyMortgagePayment);

  int get childExpenses =>
      (children * occupation.monthlyExpenses * 0.1).round();

  int get totalMonthlyExpenses =>
      occupation.monthlyExpenses + childExpenses + totalLiabilityPayment;

  int get monthlyCashflow => totalMonthlyIncome - totalMonthlyExpenses;

  int get totalAssetValue =>
      assets.fold(0, (sum, a) => sum + a.currentValue);

  int get totalDebt =>
      liabilities.fold(0, (sum, l) => sum + l.totalOwed) +
      assets.fold(0, (sum, a) => sum + a.mortgage);

  int get netWorth => cashOnHand + totalAssetValue - totalDebt;

  /// Tiến độ thoát Rat Race: Passive Income / Total Expenses
  double get financialFreedomProgress =>
      totalMonthlyExpenses > 0
          ? (passiveIncome / totalMonthlyExpenses).clamp(0.0, 1.0)
          : 1.0;

  bool get isFinanciallyFree => passiveIncome >= totalMonthlyExpenses;

  bool get isBankrupt => cashOnHand < 0 && netWorth < -5000;

  GameState copyWith({
    int? boardPosition,
    int? currentTurn,
    int? downsizeTurns,
    int? cashOnHand,
    int? monthlyIncome,
    int? monthlyExpenses,
    int? children,
    int? creditScore,
    List<Asset>? assets,
    List<Liability>? liabilities,
    EconomyState? economyState,
    double? inflationRate,
    int? xp,
    int? level,
  }) {
    return GameState(
      playerId: playerId,
      occupation: occupation,
      boardPosition: boardPosition ?? this.boardPosition,
      currentTurn: currentTurn ?? this.currentTurn,
      downsizeTurns: downsizeTurns ?? this.downsizeTurns,
      cashOnHand: cashOnHand ?? this.cashOnHand,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyExpenses: monthlyExpenses ?? this.monthlyExpenses,
      children: children ?? this.children,
      creditScore: creditScore ?? this.creditScore,
      assets: assets ?? this.assets,
      liabilities: liabilities ?? this.liabilities,
      economyState: economyState ?? this.economyState,
      inflationRate: inflationRate ?? this.inflationRate,
      xp: xp ?? this.xp,
      level: level ?? this.level,
    );
  }

  @override
  List<Object?> get props => [
        playerId,
        boardPosition,
        currentTurn,
        cashOnHand,
        assets,
        liabilities,
        economyState,
        xp,
      ];

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'occupationId': occupation.id,
        'boardPosition': boardPosition,
        'currentTurn': currentTurn,
        'downsizeTurns': downsizeTurns,
        'cashOnHand': cashOnHand,
        'monthlyIncome': monthlyIncome,
        'monthlyExpenses': monthlyExpenses,
        'children': children,
        'creditScore': creditScore,
        'economyState': economyState.name,
        'inflationRate': inflationRate,
        'xp': xp,
        'level': level,
        'assets': assets
            .map((a) => {
                  'id': a.id,
                  'name': a.name,
                  'type': a.type.name,
                  'purchasePrice': a.purchasePrice,
                  'currentValue': a.currentValue,
                  'monthlyPassiveIncome': a.monthlyPassiveIncome,
                  'downPayment': a.downPayment,
                  'mortgage': a.mortgage,
                  'monthlyMortgagePayment': a.monthlyMortgagePayment,
                })
            .toList(),
        'liabilities': liabilities
            .map((l) => {
                  'id': l.id,
                  'name': l.name,
                  'totalOwed': l.totalOwed,
                  'monthlyPayment': l.monthlyPayment,
                })
            .toList(),
      };
}
