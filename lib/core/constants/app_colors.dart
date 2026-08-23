import 'package:flutter/material.dart';

/// Application color palette.
///
/// All colors used throughout the app are defined here
/// to maintain visual consistency and enable easy theming.
abstract final class AppColors {
  // ── Primary Palette ──────────────────────────────────────────────
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D4);

  // ── Accent / Secondary ───────────────────────────────────────────
  static const Color accent = Color(0xFF00D9A6);
  static const Color accentLight = Color(0xFF5CFFDB);
  static const Color accentDark = Color(0xFF00A87D);

  // ── Background & Surface ─────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF5F5FA);
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF16213E);

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF5F5FA);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Overlay / Lock Screen ────────────────────────────────────────
  static const Color overlayBarrier = Color(0xCC000000); // 80% black
}
