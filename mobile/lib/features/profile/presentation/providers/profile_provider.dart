import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fin_goal/core/constants/app_config.dart';
import 'package:fin_goal/app/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:fin_goal/features/profile/data/repositories/local_profile_repository_impl.dart';
import 'package:fin_goal/features/profile/domain/entities/financial_profile.dart';
import 'package:fin_goal/features/profile/domain/repositories/profile_repository.dart';

part 'profile_provider.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) {
  if (AppConfig.isOffline) {
    return LocalProfileRepositoryImpl(getIt<SharedPreferences>());
  }
  return ProfileRepositoryImpl(Supabase.instance.client);
}

// ── Onboarding State Provider ─────────────────────────────────────────────

@Riverpod(keepAlive: true)
Future<bool> hasCompletedOnboarding(Ref ref) {
  return ref.watch(profileRepositoryProvider).hasCompletedOnboarding();
}

// ── Profile Controller (StateNotifier for caching & updating) ─────────────

sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final FinancialProfile? profile; // null if not created yet
  const ProfileLoaded(this.profile);
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  @override
  ProfileState build() {
    _fetchProfile();
    return const ProfileLoading();
  }

  Future<void> _fetchProfile() async {
    final result = await ref.read(profileRepositoryProvider).getProfile();
    state = result.fold(
      (failure) => ProfileError(failure.message),
      (profile) => ProfileLoaded(profile),
    );
  }

  Future<Failure?> createProfile(FinancialProfile profile) async {
    final oldState = state;
    state = const ProfileLoading();
    final result = await ref.read(profileRepositoryProvider).createProfile(profile);
    return result.fold(
      (failure) {
        state = oldState; // revert on error
        return failure;
      },
      (newProfile) {
        state = ProfileLoaded(newProfile);
        // Invalidate onboarding check so router re-evaluates
        ref.invalidate(hasCompletedOnboardingProvider);
        return null;
      },
    );
  }

  Future<Failure?> updateProfile(FinancialProfile profile) async {
    final oldState = state;
    state = const ProfileLoading();
    final result = await ref.read(profileRepositoryProvider).updateProfile(profile);
    return result.fold(
      (failure) {
        state = oldState; // revert on error
        return failure;
      },
      (updatedProfile) {
        state = ProfileLoaded(updatedProfile);
        return null;
      },
    );
  }
}
