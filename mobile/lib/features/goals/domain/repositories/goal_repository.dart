import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/goal.dart';

abstract class GoalRepository {
  /// Fetch all active goals for the current user
  Future<Either<Failure, List<Goal>>> getGoals();

  /// Create a new goal
  Future<Either<Failure, Goal>> createGoal(Goal goal);

  /// Update an existing goal
  Future<Either<Failure, Goal>> updateGoal(Goal goal);

  /// Soft delete a goal (set isActive = false)
  Future<Either<Failure, Unit>> deleteGoal(String goalId);
  
  /// Set a goal as the primary goal
  Future<Either<Failure, Unit>> setPrimaryGoal(String goalId);
}
