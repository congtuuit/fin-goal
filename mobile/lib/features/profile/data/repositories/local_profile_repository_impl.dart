import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/profile/domain/entities/financial_profile.dart';
import 'package:fin_goal/features/profile/domain/repositories/profile_repository.dart';
import 'package:fin_goal/features/profile/data/models/financial_profile_model.dart';

class LocalProfileRepositoryImpl implements ProfileRepository {
  final SharedPreferences _prefs;
  static const _profileKey = 'local_financial_profile';
  static const _onboardingKey = 'onboarding_completed';

  const LocalProfileRepositoryImpl(this._prefs);

  @override
  Future<Either<Failure, FinancialProfile?>> getProfile() async {
    try {
      final jsonStr = _prefs.getString(_profileKey);
      if (jsonStr == null) return const Right(null);

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Right(FinancialProfileModel.fromJson(data).toEntity());
    } catch (_) {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, FinancialProfile>> createProfile(FinancialProfile profile) async {
    try {
      final model = FinancialProfileModel.fromEntity(profile);
      await _prefs.setString(_profileKey, jsonEncode(model.toJson()));
      await _prefs.setBool(_onboardingKey, true);

      return Right(profile);
    } catch (_) {
      return const Left(StorageFailure());
    }
  }

  @override
  Future<Either<Failure, FinancialProfile>> updateProfile(FinancialProfile profile) async {
    try {
      final model = FinancialProfileModel.fromEntity(profile);
      await _prefs.setString(_profileKey, jsonEncode(model.toJson()));

      return Right(profile);
    } catch (_) {
      return const Left(StorageFailure());
    }
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    return _prefs.getBool(_onboardingKey) ?? false;
  }
}
