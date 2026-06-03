import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/financial_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/financial_profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseClient _client;
  static const _onboardingKey = 'onboarding_completed';

  const ProfileRepositoryImpl(this._client);

  @override
  Future<Either<Failure, FinancialProfile?>> getProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final data = await _client
          .from('financial_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return const Right(null);
      return Right(FinancialProfileModel.fromJson(data).toEntity());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, FinancialProfile>> createProfile(FinancialProfile profile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final model = FinancialProfileModel.fromEntity(profile.copyWith(userId: userId));
      final data = await _client
          .from('financial_profiles')
          .insert(model.toJson())
          .select()
          .single();

      // Mark onboarding complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);

      return Right(FinancialProfileModel.fromJson(data).toEntity());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, FinancialProfile>> updateProfile(FinancialProfile profile) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      final model = FinancialProfileModel.fromEntity(profile);
      final data = await _client
          .from('financial_profiles')
          .update(model.toJson())
          .eq('user_id', userId)
          .select()
          .single();

      return Right(FinancialProfileModel.fromJson(data).toEntity());
    } catch (e) {
      return const Left(ServerFailure());
    }
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
}
