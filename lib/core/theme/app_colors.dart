import 'package:flutter/material.dart';

/// Semantic colors for StuDesk design systems:
/// - Light: Modern Academic Elegance with warm, comfortable tones
/// - Dark: Refined Charcoal surfaces with sufficient contrast
/// - AMOLED Dark: Obsidian True Black (#000000) for OLED battery efficiency & deep contrast
abstract final class AppColors {
  // Brand Golden-Yellow Accents
  static const Color goldLight = Color(0xFFF5BA13);
  static const Color goldDark = Color(0xFFFFD43B);
  static const Color goldHover = Color(0xFFE5A800);

  // Available accent choices for user customization
  static const Color accentGold = Color(0xFFF5BA13);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentSun = Color(0xFFEAB308);
  static const Color accentHoney = Color(0xFFD97706);

  // Light Palette
  static const Color lightCanvas = Color(0xFFF9F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF2F3F7);
  static const Color lightSurfaceHigh = Color(0xFFEAECEF);
  static const Color lightBorder = Color(0xFFE2E4EC);
  static const Color lightTextPrimary = Color(0xFF131418);
  static const Color lightTextSecondary = Color(0xFF686C78);
  static const Color lightTextMuted = Color(0xFF9B9EA9);
  static const Color lightSuccess = Color(0xFF25845B);
  static const Color lightSuccessContainer = Color(0xFFEBF7F0);
  static const Color lightWarning = Color(0xFFD98B16);
  static const Color lightWarningContainer = Color(0xFFFEF3E2);
  static const Color lightError = Color(0xFFD94A4A);
  static const Color lightErrorContainer = Color(0xFFFDE8E8);

  // Standard Charcoal Dark Palette
  static const Color darkCanvas = Color(0xFF121215);
  static const Color darkSurfaceTier1 = Color(0xFF1A1A1E);
  static const Color darkSurfaceTier2 = Color(0xFF24242A);
  static const Color darkSurfaceTier3 = Color(0xFF2F2F36);
  static const Color darkBorder = Color(0xFF2C2C36);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA0A0AD);
  static const Color darkTextMuted = Color(0xFF6E6E7A);
  static const Color darkSuccess = Color(0xFF10B981);
  static const Color darkSuccessContainer = Color(0x2610B981);
  static const Color darkWarning = Color(0xFFF59E0B);
  static const Color darkWarningContainer = Color(0x26F59E0B);
  static const Color darkError = Color(0xFFFB7185);
  static const Color darkErrorContainer = Color(0x26FB7185);

  // AMOLED True-Black (#000000) Dark Palette
  static const Color amoledCanvas = Color(0xFF000000);
  static const Color amoledSurfaceTier1 = Color(0xFF0D0D10);
  static const Color amoledSurfaceTier2 = Color(0xFF17171C);
  static const Color amoledSurfaceTier3 = Color(0xFF222228);
  static const Color amoledBorder = Color(0xFF26262F);
  static const Color amoledTextPrimary = Color(0xFFF7F7FA);
  static const Color amoledTextSecondary = Color(0xFFA3A3AF);
  static const Color amoledTextMuted = Color(0xFF70707C);
}
