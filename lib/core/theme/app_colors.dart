import 'package:flutter/material.dart';

/// Centralized, strict monochrome design tokens for StuDesk.
///
/// Refined Palette Specification:
/// - Pure black: #000000 (OLED / True Black)
/// - AMOLED background: #050505 (Deepest Canvas)
/// - Surface: #101010 (Primary cards, containers, floating bars)
/// - Elevated surface: #171717 (Higher elevation / sheets / interactive states)
/// - Borders: #252525 (Subtle, refined hairline borders)
/// - Primary text: #FFFFFF (High contrast primary emphasis)
/// - Secondary text: #A1A1AA (Neutral zinc subtitles, labels, descriptions)
/// - Muted text: #71717A (Contextual helper text, timestamps, inactive icons)
/// - Disabled text: #52525B (Disabled actions and placeholders)
abstract final class AppColors {
  // --- Strict Monochrome AMOLED / Dark Palette (Primary) ---
  static const Color pureBlack = Color(0xFF000000);
  static const Color primaryBg = Color(0xFF000000);
  static const Color amoledBg = Color(0xFF050505);
  static const Color elevatedBg = Color(0xFF050505);
  static const Color surfaceSecondary = Color(0xFF101010);
  static const Color surfaceElevated = Color(0xFF171717);
  static const Color surfaceInteractive = Color(0xFF1E1E1E);
  static const Color borderSubtle = Color(0xFF252525);
  static const Color borderStrong = Color(0xFF333333);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
  static const Color textDisabled = Color(0xFF52525B);

  // --- Neutral Status & Feedback Tokens (Monochrome, No Random Colors) ---
  static const Color statusNeutralBg = Color(0xFF171717);
  static const Color statusNeutralBorder = Color(0xFF252525);
  static const Color statusNeutralText = Color(0xFFFFFFFF);

  // --- Light Mode Monochrome Counterparts (Preserved) ---
  static const Color lightCanvas = Color(0xFFF7F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFEEEEF0);
  static const Color lightSurfaceHigh = Color(0xFFE4E4E6);
  static const Color lightBorder = Color(0xFFD4D4D8);
  static const Color lightBorderStrong = Color(0xFFA1A1AA);
  static const Color lightTextPrimary = Color(0xFF09090B);
  static const Color lightTextSecondary = Color(0xFF52525B);
  static const Color lightTextMuted = Color(0xFF71717A);
  static const Color lightTextDisabled = Color(0xFFA1A1AA);

  // --- Aliases for Backward Compatibility across theme architecture ---
  static const Color amoledCanvas = primaryBg;
  static const Color amoledSurfaceTier1 = surfaceSecondary;
  static const Color amoledSurfaceTier2 = surfaceElevated;
  static const Color amoledSurfaceTier3 = surfaceInteractive;
  static const Color amoledBorder = borderSubtle;
  static const Color amoledTextPrimary = textPrimary;
  static const Color amoledTextSecondary = textSecondary;
  static const Color amoledTextMuted = textMuted;

  static const Color darkCanvas = elevatedBg;
  static const Color darkSurfaceTier1 = surfaceSecondary;
  static const Color darkSurfaceTier2 = surfaceElevated;
  static const Color darkSurfaceTier3 = surfaceInteractive;
  static const Color darkBorder = borderSubtle;
  static const Color darkTextPrimary = textPrimary;
  static const Color darkTextSecondary = textSecondary;
  static const Color darkTextMuted = textMuted;

  // Monochrome semantic mappings
  static const Color monoWhite = Color(0xFFFFFFFF);
  static const Color monoBlack = Color(0xFF000000);
}

/// Strict spacing scale for visual consistency across StuDesk.
abstract final class AppSpacing {
  /// 4 px: minimal icon/text spacing
  static const double xxs = 4.0;

  /// 8 px: compact internal spacing
  static const double xs = 8.0;

  /// 12 px: related content spacing
  static const double sm = 12.0;

  /// 16 px: standard component spacing
  static const double md = 16.0;

  /// 20 px: comfortable card and container padding
  static const double lg = 20.0;

  /// 24 px: section spacing
  static const double xl = 24.0;

  /// 32 px: major visual separation
  static const double xxl = 32.0;
}

/// Standard border radius tokens for refined, calm corners.
abstract final class AppRadii {
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double pill = 28.0;
}
