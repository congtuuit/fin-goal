import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repositories/scenario_repository_impl.dart';
import '../../data/repositories/record_repository_impl.dart';
import '../../domain/repositories/scenario_repository.dart';
import '../../domain/repositories/record_repository.dart';
import '../../domain/entities/scenario_query.dart';
import '../../domain/entities/monthly_record.dart';

part 'scenario_provider.g.dart';

@riverpod
ScenarioRepository scenarioRepository(Ref ref) {
  return ScenarioRepositoryImpl(Supabase.instance.client);
}

@riverpod
RecordRepository recordRepository(Ref ref) {
  return RecordRepositoryImpl(Supabase.instance.client);
}

@riverpod
class ScenarioQueriesNotifier extends _$ScenarioQueriesNotifier {
  @override
  FutureOr<List<ScenarioQuery>> build(String goalId) async {
    final result = await ref.read(scenarioRepositoryProvider).getQueries(goalId);
    return result.fold(
      (failure) => throw failure,
      (queries) => queries,
    );
  }

  Future<void> saveQuery(ScenarioQuery query) async {
    final result = await ref.read(scenarioRepositoryProvider).saveQuery(query);
    result.fold(
      (failure) => null, // ignore error for now
      (newQuery) {
        if (state.value != null) {
          state = AsyncData([newQuery, ...state.value!]);
        }
      },
    );
  }
}

@riverpod
class RecordsNotifier extends _$RecordsNotifier {
  @override
  FutureOr<List<MonthlyRecord>> build(String goalId) async {
    final result = await ref.read(recordRepositoryProvider).getRecords(goalId);
    return result.fold(
      (failure) => throw failure,
      (records) => records,
    );
  }

  Future<Failure?> saveRecord(MonthlyRecord record) async {
    final result = await ref.read(recordRepositoryProvider).saveRecord(record);
    return result.fold(
      (failure) => failure,
      (newRecord) {
        if (state.value != null) {
          // Replace if exists, else add
          final existing = state.value!;
          final idx = existing.indexWhere((r) => 
            r.recordMonth.year == newRecord.recordMonth.year && 
            r.recordMonth.month == newRecord.recordMonth.month);
            
          if (idx >= 0) {
            existing[idx] = newRecord;
            state = AsyncData([...existing]);
          } else {
            state = AsyncData([newRecord, ...existing]);
          }
        }
        return null;
      },
    );
  }
}

@riverpod
Future<bool> hasCheckedInThisMonth(Ref ref, String goalId) async {
  final result = await ref.read(recordRepositoryProvider).hasCheckedInThisMonth(goalId, DateTime.now());
  return result.fold((l) => false, (r) => r);
}
