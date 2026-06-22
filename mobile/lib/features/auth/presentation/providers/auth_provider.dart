import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/constants/app_config.dart';
import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fin_goal/features/auth/data/repositories/local_auth_repository_impl.dart';
import 'package:fin_goal/features/auth/domain/entities/app_user.dart';
import 'package:fin_goal/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_goal/features/auth/domain/repositories/data_sync_repository.dart';
import 'package:fin_goal/features/auth/data/repositories/data_sync_repository_impl.dart';

part 'auth_provider.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────

@riverpod
AuthRepository authRepository(Ref ref) {
  if (AppConfig.isOffline) {
    return LocalAuthRepositoryImpl(getIt<SharedPreferences>());
  }
  return AuthRepositoryImpl(Supabase.instance.client);
}

@riverpod
DataSyncRepository dataSyncRepository(Ref ref) {
  return DataSyncRepositoryImpl(Supabase.instance.client, getIt<SharedPreferences>());
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
  final authStateAsync = ref.watch(authStateProvider);
  return authStateAsync.maybeWhen(
    data: (user) => user,
    orElse: () => ref.read(authRepositoryProvider).getCurrentUser(),
  );
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
    
    if (result.isRight()) {
      final user = result.getOrElse(() => throw Exception());
      await ref.read(dataSyncRepositoryProvider).syncLocalDataToOnline();
      state = AuthSuccess(user);
    } else {
      final failure = result.fold((l) => l, (r) => throw Exception());
      state = AuthError(failure.message);
    }
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
        
    if (result.isRight()) {
      final user = result.getOrElse(() => throw Exception());
      await ref.read(dataSyncRepositoryProvider).syncLocalDataToOnline();
      state = AuthSuccess(user);
    } else {
      final failure = result.fold((l) => l, (r) => throw Exception());
      state = AuthError(failure.message);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    
    if (result.isRight()) {
      final user = result.getOrElse(() => throw Exception());
      // Sync local data if any
      await ref.read(dataSyncRepositoryProvider).syncLocalDataToOnline();
      ref.invalidate(hasLoggedInWithGoogleProvider);
      state = AuthSuccess(user);
    } else {
      final failure = result.fold((l) => l, (r) => throw Exception());
      state = AuthError(failure.message);
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AuthIdle();
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
    state = const AuthIdle();
    return result.fold((f) => f.message, (_) => null);
  }

  Future<String?> deleteAccount() async {
    state = const AuthLoading();
    final result = await ref.read(authRepositoryProvider).deleteAccount();
    state = const AuthIdle();
    return result.fold((f) => f.message, (_) => null);
  }

  void reset() => state = const AuthIdle();
}

// ── Welcome Screen State ──────────────────────────────────────────────────
@riverpod
class HasSeenWelcome extends _$HasSeenWelcome {
  @override
  bool build() {
    return getIt<SharedPreferences>().getBool('has_seen_welcome') ?? false;
  }

  Future<void> setSeen() async {
    state = true;
    await getIt<SharedPreferences>().setBool('has_seen_welcome', true);
  }
}

// ── Google Login Status ───────────────────────────────────────────────────
@riverpod
bool hasLoggedInWithGoogle(Ref ref) {
  return getIt<SharedPreferences>().getBool('has_logged_in_with_google') ?? false;
}
