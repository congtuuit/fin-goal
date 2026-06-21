import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/scenarios/data/repositories/scenario_repository_impl.dart';
import 'package:fin_goal/features/scenarios/data/repositories/record_repository_impl.dart';
import 'package:fin_goal/features/scenarios/data/repositories/local_scenario_repository_impl.dart';
import 'package:fin_goal/features/scenarios/data/repositories/local_record_repository_impl.dart';
import 'package:fin_goal/features/scenarios/domain/repositories/scenario_repository.dart';
import 'package:fin_goal/features/scenarios/domain/repositories/record_repository.dart';
import 'package:fin_goal/features/scenarios/domain/entities/scenario_query.dart';
import 'package:fin_goal/features/scenarios/domain/entities/monthly_record.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';

part 'scenario_provider.g.dart';

@Riverpod(keepAlive: true)
ScenarioRepository scenarioRepository(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user != null && user.id != 'local_user_id') {
    return ScenarioRepositoryImpl(Supabase.instance.client);
  }
  return LocalScenarioRepositoryImpl(getIt<SharedPreferences>());
}

@Riverpod(keepAlive: true)
RecordRepository recordRepository(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user != null && user.id != 'local_user_id') {
    return RecordRepositoryImpl(Supabase.instance.client);
  }
  return LocalRecordRepositoryImpl(getIt<SharedPreferences>());
}

@Riverpod(keepAlive: true)
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

@Riverpod(keepAlive: true)
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

@Riverpod(keepAlive: true)
Future<bool> hasCheckedInThisMonth(Ref ref, String goalId) async {
  final result = await ref.read(recordRepositoryProvider).hasCheckedInThisMonth(goalId, DateTime.now());
  return result.fold((l) => false, (r) => r);
}
