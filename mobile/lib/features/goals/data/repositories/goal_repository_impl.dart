import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../models/goal_model.dart';

class GoalRepositoryImpl implements GoalRepository {
  final SupabaseClient _client;

  const GoalRepositoryImpl(this._client);

  @override
  Future<Either<Failure, List<Goal>>> getGoals() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final data = await _client
          .from('goals')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: false);

      final goals = (data as List).map((e) => GoalModel.fromJson(e).toEntity()).toList();
      return Right(goals);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Goal>> createGoal(Goal goal) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      // If this is the primary goal, we might want to unset other primary goals,
      // but for V1 we just let the DB handle it if we have triggers or do it manually.
      // Assuming free tier = 1 active goal, it's always primary.

      final model = GoalModel.fromEntity(goal.copyWith(userId: userId, isPrimary: true));
      final data = await _client
          .from('goals')
          .insert(model.toJson())
          .select()
          .single();

      return Right(GoalModel.fromJson(data).toEntity());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoal(Goal goal) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final model = GoalModel.fromEntity(goal);
      final data = await _client
          .from('goals')
          .update(model.toJson())
          .eq('id', goal.id)
          .eq('user_id', userId)
          .select()
          .single();

      return Right(GoalModel.fromJson(data).toEntity());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteGoal(String goalId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      await _client
          .from('goals')
          .update({'is_active': false})
          .eq('id', goalId)
          .eq('user_id', userId);

      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setPrimaryGoal(String goalId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      // Set all to false
      await _client
          .from('goals')
          .update({'is_primary': false})
          .eq('user_id', userId);
          
      // Set target to true
      await _client
          .from('goals')
          .update({'is_primary': true})
          .eq('id', goalId)
          .eq('user_id', userId);

      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
