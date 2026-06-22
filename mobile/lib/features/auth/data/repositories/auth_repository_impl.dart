import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/constants/app_config.dart';
import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/auth/domain/entities/app_user.dart';
import 'package:fin_goal/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_goal/features/auth/data/models/user_model.dart';
import 'package:fin_goal/app/di/injection.dart';

class AuthRepositoryImpl implements AuthRepository {
  final sb.SupabaseClient _client;
  final _localAuthStreamController = StreamController<AppUser?>.broadcast();

  AuthRepositoryImpl(this._client);

  // ── Helper Local Storage ──────────────────────────────────────────────────
  Future<void> _saveUserLocal(AppUser user) async {
    try {
      final prefs = getIt<SharedPreferences>();
      final jsonStr = jsonEncode({
        'id': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'avatarUrl': user.avatarUrl,
        'createdAt': user.createdAt.toIso8601String(),
      });
      await prefs.setString('logged_in_user', jsonStr);
    } catch (e) {
      debugPrint('Error saving user local: $e');
    }
  }

  Future<void> _clearUserLocal() async {
    try {
      final prefs = getIt<SharedPreferences>();
      await prefs.remove('logged_in_user');
    } catch (e) {
      debugPrint('Error clearing user local: $e');
    }
  }

  AppUser? _getUserLocal() {
    try {
      final prefs = getIt<SharedPreferences>();
      final jsonStr = prefs.getString('logged_in_user');
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AppUser(
        id: map['id'] as String,
        email: map['email'] as String?,
        displayName: map['displayName'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
    } catch (e) {
      debugPrint('Error reading user local: $e');
      return null;
    }
  }

  @override
  Stream<AppUser?> watchAuthState() async* {
    yield getCurrentUser();
    
    final controller = StreamController<AppUser?>.broadcast();
    
    final sub = _client.auth.onAuthStateChange.listen((event) {
      final user = event.session?.user;
      if (user != null) {
        controller.add(UserModel.fromSupabase(user).toEntity());
      } else {
        // Fallback to local guest user if Supabase has no active session
        controller.add(getCurrentUser());
      }
    });
    
    final localSub = _localAuthStreamController.stream.listen(controller.add);
    
    try {
      yield* controller.stream;
    } finally {
      await sub.cancel();
      await localSub.cancel();
      await controller.close();
    }
  }

  @override
  AppUser? getCurrentUser() {
    // Read directly from app local storage first
    final localUser = _getUserLocal();
    if (localUser != null) return localUser;

    // Check if there is an online Supabase user session (e.g. initial setup)
    final user = _client.auth.currentUser;
    if (user != null) {
      final entity = UserModel.fromSupabase(user).toEntity();
      _saveUserLocal(entity);
      return entity;
    }
    
    // Fallback to local guest username (backward compatibility)
    final prefs = getIt<SharedPreferences>();
    final name = prefs.getString('local_username');
    if (name != null && name.isNotEmpty) {
      final guestUser = AppUser(
        id: 'local_user_id', 
        displayName: name, 
        email: 'offline@fingoal.local', 
        createdAt: DateTime.now()
      );
      _saveUserLocal(guestUser);
      return guestUser;
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
      final entity = UserModel.fromSupabase(user).toEntity();
      await _saveUserLocal(entity);
      return Right(entity);
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
      final entity = UserModel.fromSupabase(user).toEntity();
      await _saveUserLocal(entity);
      return Right(entity);
    } on sb.AuthException catch (e) {
      return Left(AuthFailure(message: _translateAuthError(e.message), code: e.statusCode));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() async {
    try {
      debugPrint('--- Google Sign-In Diagnostic ---');
      debugPrint('AppConfig.googleWebClientId: "${AppConfig.googleWebClientId}"');
      debugPrint('AppConfig.googleIosClientId: "${AppConfig.googleIosClientId}"');
      debugPrint('Platform: ${Platform.isIOS ? "iOS" : "Android"}');
      
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? AppConfig.googleIosClientId : null,
        serverClientId: AppConfig.googleWebClientId.isNotEmpty ? AppConfig.googleWebClientId : null,
      );
      
      debugPrint('GoogleSignIn initialized with serverClientId: "${googleSignIn.serverClientId}"');
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In: User cancelled the flow.');
        return const Left(AuthFailure(message: 'Đăng nhập Google bị hủy.'));
      }
      
      debugPrint('Google Sign-In: User signed in successfully: ${googleUser.email}');
      
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      
      debugPrint('Google Sign-In credentials fetched:');
      debugPrint('  idToken is null: ${idToken == null}');
      debugPrint('  idToken length: ${idToken?.length}');
      debugPrint('  accessToken is null: ${accessToken == null}');
      debugPrint('  accessToken length: ${accessToken?.length}');
      
      if (idToken == null) {
        debugPrint('Google Sign-In ERROR: idToken is null. Check if the package name and SHA-1 keys are properly registered in Google Cloud Console!');
        return const Left(AuthFailure(message: 'Không tìm thấy ID Token từ Google.'));
      }
      
      final response = await _client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      final user = response.user;
      if (user == null) return const Left(AuthFailure(message: 'Không thể xác thực với Supabase.'));
      
      final prefs = getIt<SharedPreferences>();
      await prefs.setBool('has_logged_in_with_google', true);
      
      final entity = UserModel.fromSupabase(user).toEntity();
      await _saveUserLocal(entity);
      
      return Right(entity);
    } on sb.AuthException catch (e) {
      debugPrint('Google Sign-In Supabase AuthException: ${e.message} (status: ${e.statusCode})');
      return Left(AuthFailure(
        message: 'Xác thực Supabase thất bại: ${e.message}', 
        code: e.statusCode?.toString()
      ));
    } catch (e) {
      debugPrint('Google Sign-In General Exception: $e');
      return Left(AuthFailure(message: 'Lỗi hệ thống: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _clearUserLocal();
      final prefs = getIt<SharedPreferences>();
      await prefs.remove('local_username');
      
      try {
        final googleSignIn = GoogleSignIn(
          clientId: Platform.isIOS ? AppConfig.googleIosClientId : null,
          serverClientId: AppConfig.googleWebClientId.isNotEmpty ? AppConfig.googleWebClientId : null,
        );
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('Google Sign-Out error: $e');
      }

      _localAuthStreamController.add(null);
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
      
      final user = AppUser(
        id: 'local_user_id',
        displayName: trimmedName,
        email: 'offline@fingoal.local',
        createdAt: DateTime.now(),
      );
      
      await _saveUserLocal(user);
      final prefs = getIt<SharedPreferences>();
      await prefs.setString('local_username', trimmedName);
      
      _localAuthStreamController.add(user);
      return Right(user);
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

      // Also sign out from Google Sign-In so that they can sign in/sign up again next time!
      try {
        final googleSignIn = GoogleSignIn(
          clientId: Platform.isIOS ? AppConfig.googleIosClientId : null,
          serverClientId: AppConfig.googleWebClientId.isNotEmpty ? AppConfig.googleWebClientId : null,
        );
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('Google Sign-Out during account deletion error: $e');
      }
      
      await _clearUserLocal();
      _localAuthStreamController.add(null);
      final prefs = getIt<SharedPreferences>();
      await prefs.remove('has_logged_in_with_google');
      // Sign out locally to clear session cache since user record is deleted
      await _client.auth.signOut(scope: sb.SignOutScope.local);
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
