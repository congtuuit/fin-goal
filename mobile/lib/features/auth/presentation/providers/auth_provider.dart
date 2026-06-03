import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../app/di/injection.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/local_auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────

@riverpod
AuthRepository authRepository(Ref ref) {
  if (AppConfig.isOffline) {
    return LocalAuthRepositoryImpl(getIt<SharedPreferences>());
  }
  return AuthRepositoryImpl(Supabase.instance.client);
}

// ── Auth State Providers ──────────────────────────────────────────────────

/// Watches auth state reactively — rebuilds on sign in / sign out.
@riverpod
Stream<AppUser?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
}

/// Current user — null if not logged in.
@riverpod
AppUser? currentUser(Ref ref) {
  return ref.watch(authRepositoryProvider).getCurrentUser();
}

/// True if user is authenticated.
@riverpod
bool isAuthenticated(Ref ref) {
  return ref.watch(currentUserProvider) != null;
}

// ── Auth Status Sealed Class ──────────────────────────────────────────────

sealed class AuthStatus {
  const AuthStatus();
}

class AuthIdle extends AuthStatus {
  const AuthIdle();
}

class AuthLoading extends AuthStatus {
  const AuthLoading();
}

class AuthSuccess extends AuthStatus {
  final AppUser user;
  const AuthSuccess(this.user);
}

class AuthError extends AuthStatus {
  final String message;
  const AuthError(this.message);
}

// ── Auth Notifier ─────────────────────────────────────────────────────────

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthStatus build() => const AuthIdle();

  Future<void> signInWithName(String name) async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).signInWithName(name);
    state = result.fold(
      (failure) => AuthError(failure.message),
      (user) => AuthSuccess(user),
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).signInWithEmail(
          email: email,
          password: password,
        );
    state = result.fold(
      (failure) => AuthError(failure.message),
      (user) => AuthSuccess(user),
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).signUpWithEmail(
          email: email,
          password: password,
        );
    state = result.fold(
      (failure) => AuthError(failure.message),
      (user) => AuthSuccess(user),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = result.fold(
      (failure) => AuthError(failure.message),
      (user) => AuthSuccess(user),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthIdle();
  }

  void reset() => state = const AuthIdle();
}
