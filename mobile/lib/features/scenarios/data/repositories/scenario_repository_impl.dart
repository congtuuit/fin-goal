import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dartz/dartz.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/scenarios/domain/entities/scenario_query.dart';
import 'package:fin_goal/features/scenarios/domain/repositories/scenario_repository.dart';
import 'package:fin_goal/features/scenarios/data/models/scenario_query_model.dart';

class ScenarioRepositoryImpl implements ScenarioRepository {
  final SupabaseClient _client;

  const ScenarioRepositoryImpl(this._client);

  @override
  Future<Either<Failure, ScenarioQuery>> saveQuery(ScenarioQuery query) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final model = ScenarioQueryModel.fromEntity(query.copyWith(userId: userId));
      final data = await _client
          .from('scenario_queries')
          .insert(model.toJson())
          .select()
          .single();

      return Right(ScenarioQueryModel.fromJson(data).toEntity());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<ScenarioQuery>>> getQueries(String goalId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final data = await _client
          .from('scenario_queries')
          .select()
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .order('created_at', ascending: false);

      final queries = (data as List).map((e) => ScenarioQueryModel.fromJson(e).toEntity()).toList();
      return Right(queries);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
