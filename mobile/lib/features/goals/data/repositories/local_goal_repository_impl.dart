import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/goals/domain/entities/goal.dart';
import 'package:fin_goal/features/goals/domain/repositories/goal_repository.dart';
import 'package:fin_goal/features/goals/data/models/goal_model.dart';

class LocalGoalRepositoryImpl implements GoalRepository {
  final SharedPreferences _prefs;
  static const _keyGoals = 'local_goals';

  const LocalGoalRepositoryImpl(this._prefs);

  List<GoalModel> _loadLocalModels() {
    final list = _prefs.getStringList(_keyGoals) ?? [];
    return list.map((e) => GoalModel.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  Future<void> _saveLocalModels(List<GoalModel> models) async {
    final list = models.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_keyGoals, list);
  }

  @override
  Future<Either<Failure, List<Goal>>> getGoals() async {
    try {
      final models = _loadLocalModels();
      final activeGoals = models
          .where((m) => m.isActive)
          .map((m) => m.toEntity())
          .toList();
      
      // Sắp xếp theo sortOrder tăng dần, sau đó theo createdAt giảm dần
      activeGoals.sort((a, b) {
        final cmp = a.sortOrder.compareTo(b.sortOrder);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });

      return Right(activeGoals);
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể đọc danh sách mục tiêu cục bộ.'));
    }
  }

  @override
  Future<Either<Failure, Goal>> createGoal(Goal goal) async {
    try {
      final models = _loadLocalModels();
      
      final newId = goal.id.isEmpty 
          ? 'local_goal_${DateTime.now().millisecondsSinceEpoch}' 
          : goal.id;
      
      // Nếu goal mới là primary, unset các primary cũ
      List<GoalModel> updatedModels = [];
      if (goal.isPrimary) {
        updatedModels = models.map((m) => GoalModel(
          id: m.id,
          userId: m.userId,
          type: m.type,
          name: m.name,
          targetAmount: m.targetAmount,
          emoji: m.emoji,
          isActive: m.isActive,
          isPrimary: false,
          sortOrder: m.sortOrder,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
        )).toList();
      } else {
        updatedModels = List.from(models);
      }

      final newModel = GoalModel.fromEntity(goal.copyWith(
        id: newId,
        userId: 'local_user_id',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      updatedModels.add(newModel);
      await _saveLocalModels(updatedModels);

      return Right(newModel.toEntity());
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể tạo mục tiêu mới.'));
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoal(Goal goal) async {
    try {
      final models = _loadLocalModels();
      final index = models.indexWhere((m) => m.id == goal.id);
      if (index == -1) {
        return const Left(StorageFailure(message: 'Mục tiêu không tồn tại.'));
      }

      List<GoalModel> updatedModels = List.from(models);
      
      // Nếu cập nhật thành primary, unset các primary khác
      if (goal.isPrimary) {
        updatedModels = updatedModels.map((m) => GoalModel(
          id: m.id,
          userId: m.userId,
          type: m.type,
          name: m.name,
          targetAmount: m.targetAmount,
          emoji: m.emoji,
          isActive: m.isActive,
          isPrimary: m.id == goal.id, // chỉ set true cho goal hiện tại
          sortOrder: m.sortOrder,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
        )).toList();
      }

      final updatedModel = GoalModel.fromEntity(goal.copyWith(
        updatedAt: DateTime.now(),
      ));
      
      if (goal.isPrimary) {
        // Đã map toàn bộ ở trên, chỉ cần thay thế đúng vị trí
        final idx = updatedModels.indexWhere((m) => m.id == goal.id);
        if (idx != -1) updatedModels[idx] = updatedModel;
      } else {
        updatedModels[index] = updatedModel;
      }

      await _saveLocalModels(updatedModels);
      return Right(updatedModel.toEntity());
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể cập nhật mục tiêu.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteGoal(String goalId) async {
    try {
      final models = _loadLocalModels();
      final index = models.indexWhere((m) => m.id == goalId);
      if (index == -1) {
        return const Left(StorageFailure(message: 'Mục tiêu không tồn tại.'));
      }

      final updatedModels = List<GoalModel>.from(models);
      // Soft delete: Cập nhật isActive = false
      final m = updatedModels[index];
      updatedModels[index] = GoalModel(
        id: m.id,
        userId: m.userId,
        type: m.type,
        name: m.name,
        targetAmount: m.targetAmount,
        emoji: m.emoji,
        isActive: false,
        isPrimary: false, // delete thì không làm primary nữa
        sortOrder: m.sortOrder,
        createdAt: m.createdAt,
        updatedAt: DateTime.now(),
      );

      await _saveLocalModels(updatedModels);
      return const Right(unit);
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể xóa mục tiêu.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setPrimaryGoal(String goalId) async {
    try {
      final models = _loadLocalModels();
      final hasGoal = models.any((m) => m.id == goalId);
      if (!hasGoal) {
        return const Left(StorageFailure(message: 'Mục tiêu không tồn tại.'));
      }

      final updatedModels = models.map((m) {
        final isTarget = m.id == goalId;
        return GoalModel(
          id: m.id,
          userId: m.userId,
          type: m.type,
          name: m.name,
          targetAmount: m.targetAmount,
          emoji: m.emoji,
          isActive: m.isActive,
          isPrimary: isTarget,
          sortOrder: m.sortOrder,
          createdAt: m.createdAt,
          updatedAt: isTarget ? DateTime.now() : m.updatedAt,
        );
      }).toList();

      await _saveLocalModels(updatedModels);
      return const Right(unit);
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể cấu hình mục tiêu chính.'));
    }
  }
}
