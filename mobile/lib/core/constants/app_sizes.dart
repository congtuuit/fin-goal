/// App spacing, border radius, and sizing constants.
/// Use these instead of magic numbers throughout the codebase.
abstract class AppSizes {
  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // ── Icon sizes ────────────────────────────────────────────────────────────
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ── Button heights ────────────────────────────────────────────────────────
  static const double buttonHeight = 54.0;
  static const double buttonHeightSm = 40.0;

  // ── Input ─────────────────────────────────────────────────────────────────
  static const double inputHeight = 56.0;

  // ── Page padding ─────────────────────────────────────────────────────────
  static const double pageHorizontalPadding = 20.0;
  static const double pageVerticalPadding = 24.0;

  // ── Card ──────────────────────────────────────────────────────────────────
  static const double cardElevation = 0.0; // Flat design — use border instead
  static const double cardPadding = 20.0;

  // ── Scenario Dashboard specific ───────────────────────────────────────────
  static const double confidenceBarHeight = 8.0;
  static const double reliabilityIndicatorSize = 72.0;
}
