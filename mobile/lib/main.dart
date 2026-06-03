import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/constants/app_config.dart';

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

  // Dependency Injection
  await configureDependencies(flavor);

  // Sentry (production only)
  if (flavor == AppFlavor.production) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.tracesSampleRate = 0.2;
      },
      appRunner: () => runApp(const ProviderScope(child: App())),
    );
  } else {
    runApp(const ProviderScope(child: App()));
  }
}
