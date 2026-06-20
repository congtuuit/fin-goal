import 'package:dartz/dartz.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/auth/domain/entities/app_user.dart';

/// Auth repository contract.
/// Implementation lives in data layer (Supabase).
abstract class AuthRepository {
  /// Watch auth state changes reactively
  Stream<AppUser?> watchAuthState();

  /// Get current user synchronously (null if not logged in)
  AppUser? getCurrentUser();

  /// Sign in with email and password
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, AppUser>> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google OAuth
  Future<Either<Failure, AppUser>> signInWithGoogle();

  /// Sign out current user
  Future<Either<Failure, Unit>> signOut();

  /// Sign in with name (Offline Mode)
  Future<Either<Failure, AppUser>> signInWithName(String name);

  /// Send password reset email
  Future<Either<Failure, Unit>> sendPasswordResetEmail(String email);

  /// Delete account permanently
  Future<Either<Failure, Unit>> deleteAccount();
}
