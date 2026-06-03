import 'package:equatable/equatable.dart';

/// Domain entity representing a What-If scenario query
class ScenarioQuery extends Equatable {
  final String id;
  final String userId;
  final String goalId;
  final String itemName;
  final int itemCost; // VND
  final double impactMonths;
  final int? bestCaseMonths;
  final int? expectedMonths;
  final int? worstCaseMonths;
  final String? aiExplanation;
  final DateTime createdAt;

  const ScenarioQuery({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.itemName,
    required this.itemCost,
    required this.impactMonths,
    this.bestCaseMonths,
    this.expectedMonths,
    this.worstCaseMonths,
    this.aiExplanation,
    required this.createdAt,
  });

  ScenarioQuery copyWith({
    String? id,
    String? userId,
    String? goalId,
    String? itemName,
    int? itemCost,
    double? impactMonths,
    int? bestCaseMonths,
    int? expectedMonths,
    int? worstCaseMonths,
    String? aiExplanation,
    DateTime? createdAt,
  }) {
    return ScenarioQuery(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      itemName: itemName ?? this.itemName,
      itemCost: itemCost ?? this.itemCost,
      impactMonths: impactMonths ?? this.impactMonths,
      bestCaseMonths: bestCaseMonths ?? this.bestCaseMonths,
      expectedMonths: expectedMonths ?? this.expectedMonths,
      worstCaseMonths: worstCaseMonths ?? this.worstCaseMonths,
      aiExplanation: aiExplanation ?? this.aiExplanation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        goalId,
        itemName,
        itemCost,
        impactMonths,
        bestCaseMonths,
        expectedMonths,
        worstCaseMonths,
        aiExplanation,
        createdAt,
      ];
}
