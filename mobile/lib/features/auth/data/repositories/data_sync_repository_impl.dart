import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:fin_goal/core/errors/failures.dart';
import 'package:fin_goal/features/auth/domain/repositories/data_sync_repository.dart';
import 'package:fin_goal/features/profile/data/models/financial_profile_model.dart';

class DataSyncRepositoryImpl implements DataSyncRepository {
  final SupabaseClient _client;
  final SharedPreferences _prefs;

  const DataSyncRepositoryImpl(this._client, this._prefs);

  @override
  Future<Either<Failure, Unit>> syncLocalDataToOnline() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      // 1. Sync Profile
      final profileStr = _prefs.getString('local_financial_profile');
      if (profileStr != null) {
        final profileJson = jsonDecode(profileStr) as Map<String, dynamic>;
        final profileModel = FinancialProfileModel.fromJson(profileJson);
        final updatedJson = FinancialProfileModel(
          userId: userId,
          age: profileModel.age,
          monthlyIncome: profileModel.monthlyIncome,
          fixedExpenses: profileModel.fixedExpenses,
          salaryDate: profileModel.salaryDate,
          purchasedGoalSlots: profileModel.purchasedGoalSlots,
        ).toJson();
        
        await _client.from('financial_profiles').upsert(updatedJson);
        debugPrint('DataSync: Synchronized financial profile successfully.');
      }

      // 2. Sync Goals & build mapping
      final goalsList = _prefs.getStringList('local_goals') ?? [];
      final Map<String, String> goalIdMapping = {}; // local_id -> supabase_uuid

      if (goalsList.isNotEmpty) {
        for (final goalStr in goalsList) {
          final goalJson = jsonDecode(goalStr) as Map<String, dynamic>;
          final localGoalId = goalJson['id'] as String;
          
          // Remove local non-UUID id and created/updated at to let Supabase default them
          goalJson.remove('id');
          goalJson.remove('created_at');
          goalJson.remove('updated_at');
          goalJson['user_id'] = userId;

          // Insert goal and retrieve the inserted row with new UUID
          final insertedGoal = await _client
              .from('goals')
              .insert(goalJson)
              .select('id')
              .single();
              
          final supabaseGoalId = insertedGoal['id'] as String;
          goalIdMapping[localGoalId] = supabaseGoalId;
        }
        debugPrint('DataSync: Synchronized ${goalIdMapping.length} goals successfully.');
      }

      // 3. Sync Monthly Records
      final recordsList = _prefs.getStringList('local_records') ?? [];
      if (recordsList.isNotEmpty) {
        final List<Map<String, dynamic>> recordsToInsert = [];
        for (final recordStr in recordsList) {
          final recordJson = jsonDecode(recordStr) as Map<String, dynamic>;
          final localGoalId = recordJson['goal_id'] as String;
          
          if (goalIdMapping.containsKey(localGoalId)) {
            recordJson['goal_id'] = goalIdMapping[localGoalId];
            recordJson['user_id'] = userId;
            recordJson.remove('id');
            recordJson.remove('created_at');
            recordsToInsert.add(recordJson);
          }
        }
        
        if (recordsToInsert.isNotEmpty) {
          await _client.from('monthly_records').insert(recordsToInsert);
          debugPrint('DataSync: Synchronized ${recordsToInsert.length} monthly records successfully.');
        }
      }

      // 4. Sync Scenario Queries
      final scenariosList = _prefs.getStringList('local_scenarios') ?? [];
      if (scenariosList.isNotEmpty) {
        final List<Map<String, dynamic>> scenariosToInsert = [];
        for (final scenarioStr in scenariosList) {
          final scenarioJson = jsonDecode(scenarioStr) as Map<String, dynamic>;
          final localGoalId = scenarioJson['goal_id'] as String;
          
          if (goalIdMapping.containsKey(localGoalId)) {
            scenarioJson['goal_id'] = goalIdMapping[localGoalId];
            scenarioJson['user_id'] = userId;
            scenarioJson.remove('id');
            scenarioJson.remove('created_at');
            scenariosToInsert.add(scenarioJson);
          }
        }
        
        if (scenariosToInsert.isNotEmpty) {
          await _client.from('scenario_queries').insert(scenariosToInsert);
          debugPrint('DataSync: Synchronized ${scenariosToInsert.length} scenario queries successfully.');
        }
      }

      // 5. Clear local guest cache
      await _prefs.remove('local_financial_profile');
      await _prefs.remove('local_goals');
      await _prefs.remove('local_records');
      await _prefs.remove('local_scenarios');
      await _prefs.remove('local_username');
      await _prefs.setBool('onboarding_completed', true); // set online onboarding completed too
      
      debugPrint('DataSync: Cleared local guest cache successfully.');

      return const Right(unit);
    } catch (e) {
      debugPrint('DataSync ERROR: $e');
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }
}
