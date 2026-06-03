import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/scenario_query.dart';
import '../../domain/repositories/scenario_repository.dart';
import '../models/scenario_query_model.dart';

class LocalScenarioRepositoryImpl implements ScenarioRepository {
  final SharedPreferences _prefs;
  static const _keyScenarios = 'local_scenarios';

  const LocalScenarioRepositoryImpl(this._prefs);

  List<ScenarioQueryModel> _loadLocalModels() {
    final list = _prefs.getStringList(_keyScenarios) ?? [];
    return list.map((e) => ScenarioQueryModel.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  Future<void> _saveLocalModels(List<ScenarioQueryModel> models) async {
    final list = models.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_keyScenarios, list);
  }

  @override
  Future<Either<Failure, ScenarioQuery>> saveQuery(ScenarioQuery query) async {
    try {
      final models = _loadLocalModels();
      
      final newId = query.id.isEmpty 
          ? 'local_query_${DateTime.now().millisecondsSinceEpoch}' 
          : query.id;

      final newModel = ScenarioQueryModel.fromEntity(query.copyWith(
        id: newId,
        userId: 'local_user_id',
        createdAt: DateTime.now(),
      ));

      final updatedModels = List<ScenarioQueryModel>.from(models)..add(newModel);
      await _saveLocalModels(updatedModels);

      return Right(newModel.toEntity());
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể lưu kịch bản mô phỏng.'));
    }
  }

  @override
  Future<Either<Failure, List<ScenarioQuery>>> getQueries(String goalId) async {
    try {
      final models = _loadLocalModels();
      final queries = models
          .where((m) => m.goalId == goalId)
          .map((m) => m.toEntity())
          .toList();

      // Sắp xếp thời gian tạo giảm dần (mới nhất trước)
      queries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return Right(queries);
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể đọc lịch sử kịch bản.'));
    }
  }
}
