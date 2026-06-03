/// App-wide configuration constants.
/// Values are injected per flavor via --dart-define at build time.
class AppConfig {
  AppConfig._();

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321', // local dev default
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-local-anon-key',
  );

  // ── Sentry ────────────────────────────────────────────────────────────────
  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // ── RevenueCat ────────────────────────────────────────────────────────────
  static const revenueCatAppleKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: '',
  );
  static const revenueCatGoogleKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: '',
  );

  // ── PostHog ───────────────────────────────────────────────────────────────
  static const postHogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: '',
  );
  static const postHogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://app.posthog.com',
  );
}

/// App flavor/environment
enum AppFlavor { development, staging, production }
