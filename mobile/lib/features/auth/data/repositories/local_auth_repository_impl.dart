import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/auth/domain/entities/app_user.dart';
import 'package:fin_goal/features/auth/domain/repositories/auth_repository.dart';

class LocalAuthRepositoryImpl implements AuthRepository {
  final SharedPreferences _prefs;
  static const _keyUsername = 'local_username';
  
  // Dùng StreamController để phát tin hiệu thay đổi trạng thái Auth
  final _authStreamController = StreamController<AppUser?>.broadcast();

  LocalAuthRepositoryImpl(this._prefs);

  @override
  Stream<AppUser?> watchAuthState() async* {
    await Future.microtask(() {});
    yield getCurrentUser();
    yield* _authStreamController.stream;
  }

  @override
  AppUser? getCurrentUser() {
    final name = _prefs.getString(_keyUsername);
    if (name == null || name.trim().isEmpty) return null;
    
    return AppUser(
      id: 'local_user_id',
      displayName: name,
      email: 'offline@fingoal.local',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<Either<Failure, AppUser>> signInWithName(String name) async {
    try {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        return const Left(AuthFailure(message: 'Tên không được để trống.'));
      }
      
      await _prefs.setString(_keyUsername, trimmedName);
      final user = AppUser(
        id: 'local_user_id',
        displayName: trimmedName,
        email: 'offline@fingoal.local',
        createdAt: DateTime.now(),
      );
      
      _authStreamController.add(user);
      return Right(user);
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể lưu tên người dùng.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _prefs.remove(_keyUsername);
      _authStreamController.add(null);
      return const Right(unit);
    } catch (_) {
      return const Left(StorageFailure(message: 'Lỗi khi xóa phiên đăng nhập cục bộ.'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return const Left(AuthFailure(message: 'Không khả dụng ở chế độ Offline. Vui lòng nhập tên để tiếp tục.'));
  }

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return const Left(AuthFailure(message: 'Không khả dụng ở chế độ Offline.'));
  }

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    return const Left(AuthFailure(message: 'Không khả dụng ở chế độ Offline.'));
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    // Remove only user-specific data keys. Do NOT call _prefs.clear()
    // as that would wipe global app settings (welcome flags, ai keys, etc.)

    // ── Auth & identity ──────────────────────────────────────────────────────
    await _prefs.remove(_keyUsername);
    await _prefs.remove('logged_in_user');

    // ── Onboarding ───────────────────────────────────────────────────────────
    await _prefs.remove('onboarding_completed');

    // ── Goal / scenario / profile ────────────────────────────────────────────
    await _prefs.remove('local_goals');
    await _prefs.remove('local_records');
    await _prefs.remove('local_scenarios');
    await _prefs.remove('local_financial_profile');

    // ── Cashflow game state (guest userId = 'local_user_id') ─────────────────
    await _prefs.remove('cashflow_game_v2_local_user_id');

    // ── AI Coach cache (all goalId-prefixed entries) ──────────────────────────
    final coachKeys = _prefs
        .getKeys()
        .where((k) =>
            k.startsWith('coach_advice_') ||
            k.startsWith('coach_advice_time_'))
        .toList();
    for (final k in coachKeys) {
      await _prefs.remove(k);
    }

    // ── Coach tone preference ─────────────────────────────────────────────────
    await _prefs.remove('coach_tone');

    _authStreamController.add(null);
    return const Right(unit);
  }
}
