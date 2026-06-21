/// App route names — use these constants instead of raw strings.
abstract class AppRoutes {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';

  // ── Onboarding ────────────────────────────────────────────────────────────
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';

  // ── Main shell ────────────────────────────────────────────────────────────
  static const home = '/home';
  static const dashboard = '/home/dashboard';

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
  static const legal = '/legal';

  // ── Premium ───────────────────────────────────────────────────────────────
  static const paywall = '/paywall';


  // ── Cashflow Board Game (New) ─────────────────────────────────────────────
  static const cashflowBoardGame = '/cashflow-board-game';
}
