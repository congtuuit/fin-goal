import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/cashflow/domain/entities/cashflow_state.dart';
import 'package:fin_goal/features/cashflow/domain/repositories/cashflow_repository.dart';

class LocalCashflowRepositoryImpl implements CashflowRepository {
  final SharedPreferences _prefs;

  const LocalCashflowRepositoryImpl(this._prefs);

  String _getKey(String userId) => 'cashflow_state_$userId';

  @override
  Future<Either<Failure, CashflowState?>> getCashflowState(String userId) async {
    try {
      final key = _getKey(userId);
      final jsonStr = _prefs.getString(key);
      
      if (jsonStr == null) {
        return const Right(null);
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final state = CashflowState.fromJson(json);
      
      return Right(state);
    } catch (_) {
      return const Left(StorageFailure(message: 'Lỗi khi đọc trạng thái trò chơi cục bộ.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveCashflowState(CashflowState state) async {
    try {
      final key = _getKey(state.userId);
      final jsonStr = jsonEncode(state.toJson());
      
      await _prefs.setString(key, jsonStr);
      return const Right(unit);
    } catch (_) {
      return const Left(StorageFailure(message: 'Lỗi khi lưu trạng thái trò chơi cục bộ.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetCashflowState(String userId) async {
    try {
      final key = _getKey(userId);
      await _prefs.remove(key);
      return const Right(unit);
    } catch (_) {
      return const Left(StorageFailure(message: 'Lỗi khi xóa trạng thái trò chơi.'));
    }
  }
}
