import 'package:equatable/equatable.dart';

enum OccupationCategory { professional, technical, trade, business }

class Occupation extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final OccupationCategory category;

  // Tài chính ban đầu
  final int monthlySalary;
  final int monthlyExpenses;
  final int initialCash;
  final int initialDebt; // Nợ ban đầu (vay mua nhà, xe, học)
  final int monthlyLoanPayment; // Trả nợ hàng tháng

  // Điểm tín dụng ban đầu
  final int initialCreditScore;

  // Metadata
  final String difficulty; // 'easy', 'medium', 'hard', 'expert'
  final int difficultyStars; // 1-5

  const Occupation({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.category,
    required this.monthlySalary,
    required this.monthlyExpenses,
    required this.initialCash,
    required this.initialDebt,
    required this.monthlyLoanPayment,
    required this.initialCreditScore,
    required this.difficulty,
    required this.difficultyStars,
  });

  /// Dòng tiền ban đầu hàng tháng
  int get initialMonthlyCashflow =>
      monthlySalary - monthlyExpenses - monthlyLoanPayment;

  /// Tổng chi phí hàng tháng (sinh hoạt + trả nợ)
  int get totalMonthlyExpenses => monthlyExpenses + monthlyLoanPayment;

  @override
  List<Object?> get props => [id];
}
