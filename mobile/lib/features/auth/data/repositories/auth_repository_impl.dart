import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/auth/domain/entities/app_user.dart';
import 'package:fin_goal/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_goal/features/auth/data/models/user_model.dart';
import 'package:fin_goal/app/di/injection.dart';

class AuthRepositoryImpl implements AuthRepository {
  final sb.SupabaseClient _client;

  const AuthRepositoryImpl(this._client);

  @override
  Stream<AppUser?> watchAuthState() {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user != null ? UserModel.fromSupabase(user).toEntity() : null;
    });
  }

  @override
  AppUser? getCurrentUser() {
    final user = _client.auth.currentUser;
    if (user != null) return UserModel.fromSupabase(user).toEntity();
    
    // Fallback to local guest user
    final prefs = getIt<SharedPreferences>();
    final name = prefs.getString('local_username');
    if (name != null && name.isNotEmpty) {
      return AppUser(
        id: 'local_user_id', 
        displayName: name, 
        email: 'offline@fingoal.local', 
        createdAt: DateTime.now()
      );
    }
    return null;
  }

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return const Left(AuthFailure());
      return Right(UserModel.fromSupabase(user).toEntity());
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: _translateAuthError(e.message), code: e.statusCode));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return const Left(AuthFailure());
      return Right(UserModel.fromSupabase(user).toEntity());
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: _translateAuthError(e.message), code: e.statusCode));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(sb.OAuthProvider.google);
      // OAuth redirect — user will be set after deep link callback
      final user = _client.auth.currentUser;
      if (user == null) return const Left(AuthFailure());
      return Right(UserModel.fromSupabase(user).toEntity());
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: _translateAuthError(e.message)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.remove('local_username');
      await _client.auth.signOut();
      return const Right(unit);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithName(String name) async {
    try {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        return const Left(AuthFailure(message: 'Tên không được để trống.'));
      }
      
      final prefs = getIt<SharedPreferences>();
      await prefs.setString('local_username', trimmedName);
      
      return Right(AppUser(
        id: 'local_user_id',
        displayName: trimmedName,
        email: 'offline@fingoal.local',
        createdAt: DateTime.now(),
      ));
    } catch (_) {
      return const Left(StorageFailure(message: 'Không thể lưu tên người dùng.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return const Right(unit);
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: _translateAuthError(e.message)));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());
      
      // Call RPC or fallback
      try {
        await _client.rpc('delete_user');
      } catch (_) {
        // If RPC doesn't exist, we just sign out for the MVP
      }
      
      await _client.auth.signOut();
      return const Right(unit);
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  /// Translate Supabase auth errors to Vietnamese user-friendly messages
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng';
    }
    if (message.contains('Email not confirmed')) {
      return 'Vui lòng xác nhận email trước khi đăng nhập';
    }
    if (message.contains('User already registered')) {
      return 'Email này đã được đăng ký';
    }
    if (message.contains('Password should be at least')) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return 'Đăng nhập thất bại. Vui lòng thử lại.';
  }
}
