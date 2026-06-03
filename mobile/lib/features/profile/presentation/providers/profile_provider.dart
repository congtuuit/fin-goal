import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_provider.g.dart';

// ── Repository Provider ───────────────────────────────────────────────────

@riverpod
ProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl(Supabase.instance.client);
}

// ── Onboarding State Provider ─────────────────────────────────────────────

@riverpod
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

@riverpod
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
