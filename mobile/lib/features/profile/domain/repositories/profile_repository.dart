import 'package:dartz/dartz.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/profile/domain/entities/financial_profile.dart';

abstract class ProfileRepository {
  /// Get current user's profile. Returns null if not yet created.
  Future<Either<Failure, FinancialProfile?>> getProfile();

  /// Create profile for first-time user (onboarding)
  Future<Either<Failure, FinancialProfile>> createProfile(FinancialProfile profile);

  /// Update existing profile
  Future<Either<Failure, FinancialProfile>> updateProfile(FinancialProfile profile);

  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding();
}
