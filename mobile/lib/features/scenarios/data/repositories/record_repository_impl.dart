import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/monthly_record.dart';
import '../../domain/repositories/record_repository.dart';
import '../models/monthly_record_model.dart';

class RecordRepositoryImpl implements RecordRepository {
  final SupabaseClient _client;

  const RecordRepositoryImpl(this._client);

  @override
  Future<Either<Failure, MonthlyRecord>> saveRecord(MonthlyRecord record) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final model = MonthlyRecordModel.fromEntity(record.copyWith(userId: userId));
      
      // Upsert: update if exists (based on unique constraint user_id, goal_id, record_month)
      // For Supabase, we can use upsert or just normal insert if we check first
      final data = await _client
          .from('monthly_records')
          .upsert(model.toJson(), onConflict: 'user_id, goal_id, record_month')
          .select()
          .single();

      return Right(MonthlyRecordModel.fromJson(data).toEntity());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<MonthlyRecord>>> getRecords(String goalId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final data = await _client
          .from('monthly_records')
          .select()
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .order('record_month', ascending: false);

      final records = (data as List).map((e) => MonthlyRecordModel.fromJson(e).toEntity()).toList();
      return Right(records);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> hasCheckedInThisMonth(String goalId, DateTime month) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());
      
      final startDate = DateTime(month.year, month.month, 1).toIso8601String();
      final endDate = DateTime(month.year, month.month + 1, 0).toIso8601String(); // Last day of month

      final data = await _client
          .from('monthly_records')
          .select('id')
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .gte('record_month', startDate)
          .lte('record_month', endDate)
          .limit(1);

      return Right((data as List).isNotEmpty);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }
}
