import 'package:equatable/equatable.dart';

/// Monthly record for tracking actual savings against planned
class MonthlyRecord extends Equatable {
  final String id;
  final String userId;
  final String goalId;
  final DateTime recordMonth; // Usually the first day of the month
  final int plannedSavings;
  final int? actualSavings;
  final double variancePercent; // Calculated automatically
  final double planReliability;
  final String? notes;
  final DateTime createdAt;

  const MonthlyRecord({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.recordMonth,
    required this.plannedSavings,
    this.actualSavings,
    this.variancePercent = 0.0,
    required this.planReliability,
    this.notes,
    required this.createdAt,
  });

  MonthlyRecord copyWith({
    String? id,
    String? userId,
    String? goalId,
    DateTime? recordMonth,
    int? plannedSavings,
    int? actualSavings,
    double? variancePercent,
    double? planReliability,
    String? notes,
    DateTime? createdAt,
  }) {
    return MonthlyRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      recordMonth: recordMonth ?? this.recordMonth,
      plannedSavings: plannedSavings ?? this.plannedSavings,
      actualSavings: actualSavings ?? this.actualSavings,
      variancePercent: variancePercent ?? this.variancePercent,
      planReliability: planReliability ?? this.planReliability,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        goalId,
        recordMonth,
        plannedSavings,
        actualSavings,
        variancePercent,
        planReliability,
        notes,
        createdAt,
      ];
}
