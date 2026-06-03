import 'package:equatable/equatable.dart';

enum AssetType { realEstate, business, stock, crypto, other }
enum LiabilityType { mortgage, carLoan, creditCard, personalLoan, other }

class CashflowAsset extends Equatable {
  final String id;
  final String name;
  final AssetType type;
  final int value;
  final int passiveIncome;

  const CashflowAsset({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.passiveIncome,
  });

  @override
  List<Object?> get props => [id, name, type, value, passiveIncome];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'value': value,
        'passiveIncome': passiveIncome,
      };

  factory CashflowAsset.fromJson(Map<String, dynamic> json) => CashflowAsset(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AssetType.values.byName(json['type'] as String),
        value: json['value'] as int,
        passiveIncome: json['passiveIncome'] as int,
      );
}

class CashflowLiability extends Equatable {
  final String id;
  final String name;
  final LiabilityType type;
  final int totalOwed;
  final int monthlyPayment;

  const CashflowLiability({
    required this.id,
    required this.name,
    required this.type,
    required this.totalOwed,
    required this.monthlyPayment,
  });

  @override
  List<Object?> get props => [id, name, type, totalOwed, monthlyPayment];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'totalOwed': totalOwed,
        'monthlyPayment': monthlyPayment,
      };

  factory CashflowLiability.fromJson(Map<String, dynamic> json) =>
      CashflowLiability(
        id: json['id'] as String,
        name: json['name'] as String,
        type: LiabilityType.values.byName(json['type'] as String),
        totalOwed: json['totalOwed'] as int,
        monthlyPayment: json['monthlyPayment'] as int,
      );
}

class CashflowState extends Equatable {
  final String userId;
  final int currentMonth;
  final int cashOnHand;
  
  /// Lương (Thu nhập chủ động)
  final int activeIncome;
  
  /// Chi phí cố định tối thiểu (sinh hoạt phí)
  final int baseExpenses;

  final List<CashflowAsset> assets;
  final List<CashflowLiability> liabilities;

  const CashflowState({
    required this.userId,
    required this.currentMonth,
    required this.cashOnHand,
    required this.activeIncome,
    required this.baseExpenses,
    required this.assets,
    required this.liabilities,
  });

  /// Tổng thu nhập thụ động
  int get passiveIncome => assets.fold(0, (sum, a) => sum + a.passiveIncome);

  /// Tổng chi phí (bao gồm trả nợ)
  int get totalExpenses =>
      baseExpenses + liabilities.fold(0, (sum, l) => sum + l.monthlyPayment);

  /// Tổng thu nhập
  int get totalIncome => activeIncome + passiveIncome;

  /// Dòng tiền hàng tháng (Cashflow)
  int get monthlyCashflow => totalIncome - totalExpenses;

  /// Tiến độ tự do tài chính (%)
  double get financialFreedomProgress =>
      totalExpenses > 0 ? (passiveIncome / totalExpenses).clamp(0.0, 1.0) : 1.0;

  bool get isFinanciallyFree => passiveIncome >= totalExpenses;

  CashflowState copyWith({
    String? userId,
    int? currentMonth,
    int? cashOnHand,
    int? activeIncome,
    int? baseExpenses,
    List<CashflowAsset>? assets,
    List<CashflowLiability>? liabilities,
  }) {
    return CashflowState(
      userId: userId ?? this.userId,
      currentMonth: currentMonth ?? this.currentMonth,
      cashOnHand: cashOnHand ?? this.cashOnHand,
      activeIncome: activeIncome ?? this.activeIncome,
      baseExpenses: baseExpenses ?? this.baseExpenses,
      assets: assets ?? this.assets,
      liabilities: liabilities ?? this.liabilities,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        currentMonth,
        cashOnHand,
        activeIncome,
        baseExpenses,
        assets,
        liabilities,
      ];

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'currentMonth': currentMonth,
        'cashOnHand': cashOnHand,
        'activeIncome': activeIncome,
        'baseExpenses': baseExpenses,
        'assets': assets.map((e) => e.toJson()).toList(),
        'liabilities': liabilities.map((e) => e.toJson()).toList(),
      };

  factory CashflowState.fromJson(Map<String, dynamic> json) => CashflowState(
        userId: json['userId'] as String,
        currentMonth: json['currentMonth'] as int,
        cashOnHand: json['cashOnHand'] as int,
        activeIncome: json['activeIncome'] as int,
        baseExpenses: json['baseExpenses'] as int,
        assets: (json['assets'] as List<dynamic>?)
                ?.map((e) => CashflowAsset.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        liabilities: (json['liabilities'] as List<dynamic>?)
                ?.map((e) => CashflowLiability.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
