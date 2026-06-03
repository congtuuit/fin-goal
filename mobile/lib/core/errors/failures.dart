import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
/// Use with Either<Failure, T> return types.
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// ── Network Failures ──────────────────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.',
    super.code = 'network_error',
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Lỗi máy chủ. Vui lòng thử lại sau.',
    super.code,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Kết nối quá chậm. Vui lòng thử lại.',
    super.code = 'timeout',
  });
}

// ── Auth Failures ─────────────────────────────────────────────────────────

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Xác thực thất bại. Vui lòng đăng nhập lại.',
    super.code,
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Bạn cần đăng nhập để tiếp tục.',
    super.code = 'unauthorized',
  });
}

// ── Cache Failures ────────────────────────────────────────────────────────

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Không thể đọc dữ liệu cục bộ.',
    super.code = 'cache_error',
  });
}

// ── Validation Failures ───────────────────────────────────────────────────

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code = 'validation_error'});
}

// ── Business Logic Failures ───────────────────────────────────────────────

class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure({
    super.message = 'Thu nhập không đủ để thực hiện kế hoạch này.',
    super.code = 'insufficient_funds',
  });
}

class GoalLimitReachedFailure extends Failure {
  const GoalLimitReachedFailure({
    super.message = 'Tài khoản Free chỉ hỗ trợ 1 mục tiêu. Nâng cấp Premium để tạo nhiều hơn.',
    super.code = 'goal_limit_reached',
  });
}

// ── Premium Failures ──────────────────────────────────────────────────────

class PremiumRequiredFailure extends Failure {
  const PremiumRequiredFailure({
    super.message = 'Tính năng này chỉ dành cho Premium.',
    super.code = 'premium_required',
  });
}
