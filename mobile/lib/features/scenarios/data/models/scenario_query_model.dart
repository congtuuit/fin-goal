import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/scenario_query.dart';

part 'scenario_query_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ScenarioQueryModel {
  final String? id; // null before insert
  final String userId;
  final String goalId;
  final String itemName;
  final int itemCost;
  final double impactMonths;
  final int? bestCaseMonths;
  final int? expectedMonths;
  final int? worstCaseMonths;
  final String? aiExplanation;
  final DateTime? createdAt;

  const ScenarioQueryModel({
    this.id,
    required this.userId,
    required this.goalId,
    required this.itemName,
    required this.itemCost,
    required this.impactMonths,
    this.bestCaseMonths,
    this.expectedMonths,
    this.worstCaseMonths,
    this.aiExplanation,
    this.createdAt,
  });

  factory ScenarioQueryModel.fromJson(Map<String, dynamic> json) => _$ScenarioQueryModelFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$ScenarioQueryModelToJson(this);
    if (id == null) json.remove('id');
    if (createdAt == null) json.remove('created_at');
    return json;
  }

  factory ScenarioQueryModel.fromEntity(ScenarioQuery entity) {
    return ScenarioQueryModel(
      id: entity.id,
      userId: entity.userId,
      goalId: entity.goalId,
      itemName: entity.itemName,
      itemCost: entity.itemCost,
      impactMonths: entity.impactMonths,
      bestCaseMonths: entity.bestCaseMonths,
      expectedMonths: entity.expectedMonths,
      worstCaseMonths: entity.worstCaseMonths,
      aiExplanation: entity.aiExplanation,
      createdAt: entity.createdAt,
    );
  }

  ScenarioQuery toEntity() {
    return ScenarioQuery(
      id: id ?? '',
      userId: userId,
      goalId: goalId,
      itemName: itemName,
      itemCost: itemCost,
      impactMonths: impactMonths,
      bestCaseMonths: bestCaseMonths,
      expectedMonths: expectedMonths,
      worstCaseMonths: worstCaseMonths,
      aiExplanation: aiExplanation,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
