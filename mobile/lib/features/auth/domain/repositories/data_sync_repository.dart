import 'package:dartz/dartz.dart';
import 'package:fin_goal/core/errors/failures.dart';

abstract class DataSyncRepository {
  /// Syncs all local Guest data (profile, goals, records, scenario queries) to Supabase Cloud.
  Future<Either<Failure, Unit>> syncLocalDataToOnline();
}
