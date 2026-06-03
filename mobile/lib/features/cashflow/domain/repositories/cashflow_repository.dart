import 'package:dartz/dartz.dart';
import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/cashflow/domain/entities/cashflow_state.dart';

abstract class CashflowRepository {
  /// Lấy trạng thái game hiện tại (nếu có).
  /// Trả về null nếu chưa từng chơi.
  Future<Either<Failure, CashflowState?>> getCashflowState(String userId);

  /// Lưu trạng thái game (tạo mới hoặc cập nhật).
  Future<Either<Failure, Unit>> saveCashflowState(CashflowState state);

  /// Reset game (Xóa trạng thái đã lưu).
  Future<Either<Failure, Unit>> resetCashflowState(String userId);
}
