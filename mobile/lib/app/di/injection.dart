import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fin_goal/core/constants/app_config.dart';
import 'package:fin_goal/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fin_goal/features/auth/domain/repositories/auth_repository.dart';

final getIt = GetIt.instance;

/// Configure all dependencies.
/// Called once at app startup.
Future<void> configureDependencies(AppFlavor flavor) async {
  // ── SharedPreferences (Offline storage) ───────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // ── External ──────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // ── Auth ──────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<SupabaseClient>()),
  );

  // Note: Using Riverpod for state management — get_it is for services
  // that don't need reactive state. Repos are registered here as a backup
  // but are primarily accessed via Riverpod providers.
}
