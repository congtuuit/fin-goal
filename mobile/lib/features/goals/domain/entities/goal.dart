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
  final int currentSavings; // VND (số dư hiện tại cho mục tiêu này)
  final int monthlySaving; // VND (số tiền tiết kiệm mỗi tháng cho mục tiêu này)
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
    this.currentSavings = 0,
    this.monthlySaving = 0,
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
    int? currentSavings,
    int? monthlySaving,
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
      currentSavings: currentSavings ?? this.currentSavings,
      monthlySaving: monthlySaving ?? this.monthlySaving,
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
        currentSavings,
        monthlySaving,
        emoji,
        isActive,
        isPrimary,
        sortOrder,
        createdAt,
        updatedAt,
      ];
}
