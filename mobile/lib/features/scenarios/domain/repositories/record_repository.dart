import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/monthly_record.dart';

abstract class RecordRepository {
  /// Save a monthly check-in record
  Future<Either<Failure, MonthlyRecord>> saveRecord(MonthlyRecord record);
  
  /// Get all records for a specific goal
  Future<Either<Failure, List<MonthlyRecord>>> getRecords(String goalId);
  
  /// Check if the user has already checked in this month
  Future<Either<Failure, bool>> hasCheckedInThisMonth(String goalId, DateTime month);
}
