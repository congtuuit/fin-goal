/// App route names — use these constants instead of raw strings.
abstract class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const splash = '/';
  static const login = '/login';

  // ── Onboarding ────────────────────────────────────────────────────────────
  static const onboarding = '/onboarding';

  // ── Main shell ────────────────────────────────────────────────────────────
  static const home = '/home';

  // ── Goals ─────────────────────────────────────────────────────────────────
  static const goalSelection = '/goal-selection';
  static const goalDetail = '/goal/:id';

  // ── Scenarios ─────────────────────────────────────────────────────────────
  static const scenarioDashboard = '/scenario';
  static const whatIf = '/scenario/what-if';
  static const monthlyCheckin = '/scenario/monthly-checkin';

  // ── Coach ─────────────────────────────────────────────────────────────────
  static const coachInsights = '/coach';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const profile = '/profile';
  static const editProfile = '/profile/edit';

  // ── Premium ───────────────────────────────────────────────────────────────
  static const paywall = '/paywall';

  // ── Cashflow (Legacy) ─────────────────────────────────────────────────────
  static const cashflowDashboard = '/cashflow-dashboard';
  static const cashflowGame = '/cashflow-game';

  // ── Cashflow Board Game (New) ─────────────────────────────────────────────
  static const cashflowBoardGame = '/cashflow-board-game';
}
