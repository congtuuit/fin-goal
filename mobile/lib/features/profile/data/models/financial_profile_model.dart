import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fin_goal/features/profile/domain/entities/financial_profile.dart';

part 'financial_profile_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class FinancialProfileModel {
  final String userId;
  final int age;
  final int monthlyIncome;
  final int fixedExpenses;
  final int salaryDate;

  const FinancialProfileModel({
    required this.userId,
    required this.age,
    required this.monthlyIncome,
    required this.fixedExpenses,
    required this.salaryDate,
  });

  factory FinancialProfileModel.fromJson(Map<String, dynamic> json) => 
      _$FinancialProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$FinancialProfileModelToJson(this);

  factory FinancialProfileModel.fromEntity(FinancialProfile entity) {
    return FinancialProfileModel(
      userId: entity.userId,
      age: entity.age,
      monthlyIncome: entity.monthlyIncome,
      fixedExpenses: entity.fixedExpenses,
      salaryDate: entity.salaryDate,
    );
  }

  FinancialProfile toEntity() {
    return FinancialProfile(
      userId: userId,
      age: age,
      monthlyIncome: monthlyIncome,
      fixedExpenses: fixedExpenses,
      salaryDate: salaryDate,
    );
  }
}
