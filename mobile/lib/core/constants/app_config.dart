/// App-wide configuration constants.
/// Values are injected per flavor via --dart-define at build time.
class AppConfig {
  AppConfig._();

  // ── Mode Configuration ──────────────────────────────────────────────────────
  static const isOffline = String.fromEnvironment('OFFLINE', defaultValue: 'false') == 'true';

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jpjncvzbdlvxhqqiaied.supabase.co/',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impwam5jdnpiZGx2eGhxcWlhaWVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE5NjYzNDgsImV4cCI6MjA5NzU0MjM0OH0.cqXitmYMVjnRLyD7SZNH3nnizwbemhgemuqALau0als',
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
