import 'package:flutter/material.dart';

/// Impact Nation Gospel Center — Brand Color System
/// Brand identity: Deep navy, warm gold, white — matching INGC visual identity
class AppColors {
  // ── Primary Brand (Deep Navy) ─────────────────────────────────────────────
  static const Color primary = Color(0xFF0F2057);       // Deep navy
  static const Color primaryDark = Color(0xFF07132E);   // Darker navy
  static const Color primaryLight = Color(0xFF1A3A8F);  // Lighter navy
  static const Color primarySurface = Color(0xFFEEF2FF);// Very light navy tint

  // ── Gold Accent (Brand) ──────────────────────────────────────────────────
  static const Color gold = Color(0xFFB45309);          // Deep gold/amber
  static const Color goldLight = Color(0xFFD97706);     // Warm gold
  static const Color goldBright = Color(0xFFFBBF24);    // Bright gold
  static const Color goldSurface = Color(0xFFFFFBEB);   // Gold tint

  // ── Semantic Colors ──────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF1D4ED8);     // Blue accent
  static const Color success = Color(0xFF059669);       // Emerald
  static const Color error = Color(0xFFDC2626);         // Red
  static const Color warning = Color(0xFFF59E0B);       // Amber

  // ── Gradient Presets ─────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A3A8F), Color(0xFF07132E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F2057), Color(0xFF07132E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A3A8F), Color(0xFF0F2057)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF1A1200), Color(0xFF0F2057), Color(0xFF07132E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  // ── Light Theme Surfaces ─────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEEF2FF);
  static const Color borderLight = Color(0xFFDDE3F0);

  // ── Dark Theme Surfaces ──────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF080D1A);
  static const Color surfaceDark = Color(0xFF0F1628);
  static const Color surfaceVariantDark = Color(0xFF1A243D);
  static const Color borderDark = Color(0xFF2A3555);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF0A0F2E);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF0F4FF);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
}
