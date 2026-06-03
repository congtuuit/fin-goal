import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/scenarios/domain/entities/monthly_record.dart';
import 'package:fin_goal/features/scenarios/domain/repositories/record_repository.dart';
import 'package:fin_goal/features/scenarios/data/models/monthly_record_model.dart';

class LocalRecordRepositoryImpl implements RecordRepository {
  final SharedPreferences _prefs;
  static const _keyRecords = 'local_records';

  const LocalRecordRepositoryImpl(this._prefs);

  List<MonthlyRecordModel> _loadLocalModels() {
    final list = _prefs.getStringList(_keyRecords) ?? [];
    return list.map((e) => MonthlyRecordModel.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  Future<void> _saveLocalModels(List<MonthlyRecordModel> models) async {
    final list = models.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_keyRecords, list);
  }

  @override
  Future<Either<Failure, MonthlyRecord>> saveRecord(MonthlyRecord record) async {
    try {
      final models = _loadLocalModels();
      final updatedModels = List<MonthlyRecordModel>.from(models);
      
      final index = updatedModels.indexWhere((m) => 
        m.goalId == record.goalId && 
        m.recordMonth.year == record.recordMonth.year && 
        m.recordMonth.month == record.recordMonth.month
      );

      final newId = record.id.isEmpty 
          ? 'local_record_${DateTime.now().millisecondsSinceEpoch}' 
          : record.id;

      final newModel = MonthlyRecordModel.fromEntity(record.copyWith(
        id: newId,
        userId: 'local_user_id',
        createdAt: DateTime.now(),
      ));

      if (index >= 0) {
        updatedModels[index] = newModel;
      } else {
        updatedModels.add(newModel);
      }

      await _saveLocalModels(updatedModels);
      return Right(newModel.toEntity());
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể lưu bản ghi tiến độ tháng.'));
    }
  }

  @override
  Future<Either<Failure, List<MonthlyRecord>>> getRecords(String goalId) async {
    try {
      final models = _loadLocalModels();
      final records = models
          .where((m) => m.goalId == goalId)
          .map((m) => m.toEntity())
          .toList();

      // Sắp xếp thời gian của tháng ghi chép giảm dần
      records.sort((a, b) => b.recordMonth.compareTo(a.recordMonth));

      return Right(records);
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể đọc lịch sử ghi chép.'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasCheckedInThisMonth(String goalId, DateTime month) async {
    try {
      final models = _loadLocalModels();
      final exists = models.any((m) => 
        m.goalId == goalId && 
        m.recordMonth.year == month.year && 
        m.recordMonth.month == month.month
      );

      return Right(exists);
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể kiểm tra trạng thái cập nhật tháng.'));
    }
  }
}
