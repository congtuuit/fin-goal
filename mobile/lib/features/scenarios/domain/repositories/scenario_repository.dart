import 'package:dartz/dartz.dart';
import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/scenarios/domain/entities/scenario_query.dart';

abstract class ScenarioRepository {
  /// Save a what-if query to history
  Future<Either<Failure, ScenarioQuery>> saveQuery(ScenarioQuery query);
  
  /// Get user's query history for a specific goal
  Future<Either<Failure, List<ScenarioQuery>>> getQueries(String goalId);
}
