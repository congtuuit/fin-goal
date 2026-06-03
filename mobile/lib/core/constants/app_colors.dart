import 'package:flutter/material.dart';

/// App color palette — curated HSL-based dark-first design.
/// All colors are semantically named, never use raw hex in widgets.
abstract class AppColors {
  // ── Brand / Primary ───────────────────────────────────────────────────────
  /// Main brand color — deep indigo
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF4F46E5);

  // ── Accent ────────────────────────────────────────────────────────────────
  /// Success / positive / on-track
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFF34D399);

  /// Warning / attention
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFBBF24);

  /// Danger / off-track / worst case
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFF87171);

  // ── Neutrals (Dark theme) ─────────────────────────────────────────────────
  static const backgroundDark = Color(0xFF0F0F1A);
  static const surfaceDark = Color(0xFF1A1A2E);
  static const surfaceElevatedDark = Color(0xFF252540);
  static const borderDark = Color(0xFF2E2E4A);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFF8F8FF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const textInverse = Color(0xFF111827);

  // ── Semantic ──────────────────────────────────────────────────────────────
  /// Best case highlight
  static const bestCase = success;

  /// Expected case — primary brand
  static const expectedCase = primary;

  /// Worst case — muted warning, not alarming
  static const worstCase = Color(0xFFF97316); // amber-orange

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF252540)],
  );
}
