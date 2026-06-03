import 'package:equatable/equatable.dart';

/// Domain entity for the user's financial profile.
/// This is the core input for ALL calculations.
class FinancialProfile extends Equatable {
  final String userId;
  final int age;

  /// Monthly income in VND
  final int monthlyIncome;

  /// Fixed monthly expenses in VND (rent, loan repayments, etc.)
  final int fixedExpenses;

  /// Current total savings in VND
  final int currentSavings;

  /// Day of month salary is received (1-31)
  final int salaryDate;

  const FinancialProfile({
    required this.userId,
    required this.age,
    required this.monthlyIncome,
    required this.fixedExpenses,
    required this.currentSavings,
    required this.salaryDate,
  });

  /// Disposable income after fixed expenses (how much CAN be saved/spent)
  int get disposableIncome => monthlyIncome - fixedExpenses;

  /// Suggested monthly saving amount (50% of disposable as default)
  int get suggestedMonthlySaving => (disposableIncome * 0.5).round();

  /// Saving rate as percentage
  double get savingRate =>
      monthlyIncome > 0 ? (suggestedMonthlySaving / monthlyIncome) * 100 : 0;

  bool get isHealthy => disposableIncome > 0;

  FinancialProfile copyWith({
    String? userId,
    int? age,
    int? monthlyIncome,
    int? fixedExpenses,
    int? currentSavings,
    int? salaryDate,
  }) {
    return FinancialProfile(
      userId: userId ?? this.userId,
      age: age ?? this.age,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      fixedExpenses: fixedExpenses ?? this.fixedExpenses,
      currentSavings: currentSavings ?? this.currentSavings,
      salaryDate: salaryDate ?? this.salaryDate,
    );
  }

  @override
  List<Object?> get props => [userId, age, monthlyIncome, fixedExpenses, currentSavings, salaryDate];
}
