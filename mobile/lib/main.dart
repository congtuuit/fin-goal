import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:fin_goal/app/app.dart';
import 'package:fin_goal/app/di/injection.dart';
import 'package:fin_goal/core/constants/app_config.dart';
import 'package:fin_goal/core/services/ad_service.dart';

Future<void> main() async {
  await bootstrap(AppFlavor.production);
}

/// Public bootstrap — reused by main_dev.dart and main_staging.dart
Future<void> bootstrap(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // AdMob
  await AdService.initialize();

  // Dependency Injection
  await configureDependencies(flavor);

  // Sentry (production only)
  if (flavor == AppFlavor.production) {
    // await SentryFlutter.init(
    //   (options) {
    //     options.dsn = AppConfig.sentryDsn;
    //   },
    //   appRunner: () => runApp(
    //     const ProviderScope(child: App()),
    //   ),
    // );
    runApp(const ProviderScope(child: App()));
  } else {
    runApp(const ProviderScope(child: App()));
  }
}
