import 'package:equatable/equatable.dart';

/// Supported goal types
enum GoalType {
  emergencyFund,
  car,
  house,
  wedding,
  travel,
  retirement,
  custom,
}

/// Domain entity for a financial goal.
class Goal extends Equatable {
  final String id;
  final String userId;
  final GoalType type;
  final String name;
  final int targetAmount; // VND
  final String? emoji;
  final bool isActive;
  final bool isPrimary;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.targetAmount,
    this.emoji,
    this.isActive = true,
    this.isPrimary = false,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Goal copyWith({
    String? id,
    String? userId,
    GoalType? type,
    String? name,
    int? targetAmount,
    String? emoji,
    bool? isActive,
    bool? isPrimary,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      emoji: emoji ?? this.emoji,
      isActive: isActive ?? this.isActive,
      isPrimary: isPrimary ?? this.isPrimary,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        name,
        targetAmount,
        emoji,
        isActive,
        isPrimary,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
