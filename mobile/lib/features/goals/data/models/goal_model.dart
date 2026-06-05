import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fin_goal/features/goals/domain/entities/goal.dart';

part 'goal_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GoalModel {
  final String? id; // Optional for creation
  final String userId;
  final String type;
  final String name;
  final int targetAmount;
  final int currentSavings;
  final int monthlySaving;
  final String? emoji;
  final bool isActive;
  final bool isPrimary;
  final bool isPinned;
  final String status;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GoalModel({
    this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.targetAmount,
    this.currentSavings = 0,
    this.monthlySaving = 0,
    this.emoji,
    this.isActive = true,
    this.isPrimary = false,
    this.isPinned = false,
    this.status = 'active',
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => _$GoalModelFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$GoalModelToJson(this);
    if (id == null || id!.isEmpty) {
      json.remove('id');
    }
    if (createdAt == null) {
      json.remove('created_at');
    }
    if (updatedAt == null) {
      json.remove('updated_at');
    }
    return json;
  }

  factory GoalModel.fromEntity(Goal entity) {
    return GoalModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type.name,
      name: entity.name,
      targetAmount: entity.targetAmount,
      currentSavings: entity.currentSavings,
      monthlySaving: entity.monthlySaving,
      emoji: entity.emoji,
      isActive: entity.isActive,
      isPrimary: entity.isPrimary,
      isPinned: entity.isPinned,
      status: entity.status,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Goal toEntity() {
    return Goal(
      id: id ?? '',
      userId: userId,
      type: GoalType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => GoalType.custom,
      ),
      name: name,
      targetAmount: targetAmount,
      currentSavings: currentSavings,
      monthlySaving: monthlySaving,
      emoji: emoji,
      isActive: isActive,
      isPrimary: isPrimary,
      isPinned: isPinned,
      status: status,
      sortOrder: sortOrder,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
