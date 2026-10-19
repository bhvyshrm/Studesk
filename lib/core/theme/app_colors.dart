import 'package:flutter/material.dart';

/// Semantic colors for StuDesk design systems:
/// - Light: Modern Academic Elegance
/// - Dark: Obsidian Gold (True AMOLED Black)
abstract final class AppColors {
  // Brand Golden-Yellow Accent
  static const Color goldLight = Color(0xFFFFC928);
  static const Color goldDark = Color(0xFFFFD43B);
  static const Color goldHover = Color(0xFFF4AE00);

  // Light Palette
  static const Color lightCanvas = Color(0xFFF8F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F2F5);
  static const Color lightSurfaceHigh = Color(0xFFE9E7ED);
  static const Color lightBorder = Color(0xFFE7E8ED);
  static const Color lightTextPrimary = Color(0xFF17181C);
  static const Color lightTextSecondary = Color(0xFF777A84);
  static const Color lightTextMuted = Color(0xFFA0A3AD);
  static const Color lightSuccess = Color(0xFF25845B);
  static const Color lightSuccessContainer = Color(0xFFEBF7F0);
  static const Color lightWarning = Color(0xFFD98B16);
  static const Color lightWarningContainer = Color(0xFFFEF3E2);
  static const Color lightError = Color(0xFFD94A4A);
  static const Color lightErrorContainer = Color(0xFFFDE8E8);

  // AMOLED Dark Palette
  static const Color darkCanvas = Color(0xFF000000);
  static const Color darkSurfaceTier1 = Color(0xFF0A0A0C);
  static const Color darkSurfaceTier2 = Color(0xFF141417);
  static const Color darkSurfaceTier3 = Color(0xFF1C1C20);
  static const Color darkBorder = Color(0xFF29292F);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextMuted = Color(0xFF71717A);
  static const Color darkSuccess = Color(0xFF10B981);
  static const Color darkSuccessContainer = Color(0x2610B981);
  static const Color darkWarning = Color(0xFFF59E0B);
  static const Color darkWarningContainer = Color(0x26F59E0B);
  static const Color darkError = Color(0xFFFB7185);
  static const Color darkErrorContainer = Color(0x26FB7185);
}
