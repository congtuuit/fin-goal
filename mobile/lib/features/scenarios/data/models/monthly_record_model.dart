import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fin_goal/features/scenarios/domain/entities/monthly_record.dart';

part 'monthly_record_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class MonthlyRecordModel {
  final String? id;
  final String userId;
  final String goalId;
  final DateTime recordMonth;
  final int plannedSavings;
  final int? actualSavings;
  final double variancePercent;
  final double planReliability;
  final String? notes;
  final DateTime? createdAt;

  const MonthlyRecordModel({
    this.id,
    required this.userId,
    required this.goalId,
    required this.recordMonth,
    required this.plannedSavings,
    this.actualSavings,
    this.variancePercent = 0.0,
    required this.planReliability,
    this.notes,
    this.createdAt,
  });

  factory MonthlyRecordModel.fromJson(Map<String, dynamic> json) => _$MonthlyRecordModelFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$MonthlyRecordModelToJson(this);
    if (id == null) json.remove('id');
    if (createdAt == null) json.remove('created_at');
    return json;
  }

  factory MonthlyRecordModel.fromEntity(MonthlyRecord entity) {
    return MonthlyRecordModel(
      id: entity.id,
      userId: entity.userId,
      goalId: entity.goalId,
      recordMonth: entity.recordMonth,
      plannedSavings: entity.plannedSavings,
      actualSavings: entity.actualSavings,
      variancePercent: entity.variancePercent,
      planReliability: entity.planReliability,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  MonthlyRecord toEntity() {
    return MonthlyRecord(
      id: id ?? '',
      userId: userId,
      goalId: goalId,
      recordMonth: recordMonth,
      plannedSavings: plannedSavings,
      actualSavings: actualSavings,
      variancePercent: variancePercent,
      planReliability: planReliability,
      notes: notes,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
