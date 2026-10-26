import 'package:flutter/material.dart';

/// Centralized, strict monochrome design tokens for StuDesk.
///
/// Palette Specification:
/// - Primary background: #000000 (True Obsidian Black)
/// - Elevated background: #0A0A0A (Raised canvas)
/// - Secondary surface: #111111 (Cards and containers)
/// - Elevated surface: #171717 (Higher elevation / sheets / dialogs)
/// - Interactive surface: #1E1E1E (Hover / focus / active states)
/// - Subtle border: #292929 (Hairline dividers and containers)
/// - Strong border: #3A3A3A (Focused inputs and active outlines)
/// - Primary text: #FFFFFF (High contrast primary emphasis)
/// - Secondary text: #B3B3B3 (Subtitles, labels, descriptions)
/// - Muted text: #858585 (Contextual helper text, timestamps)
/// - Disabled text: #626262 (Disabled actions and placeholders)
abstract final class AppColors {
  // --- Strict Monochrome AMOLED / Dark Palette (Primary) ---
  static const Color primaryBg = Color(0xFF000000);
  static const Color elevatedBg = Color(0xFF0A0A0A);
  static const Color surfaceSecondary = Color(0xFF111111);
  static const Color surfaceElevated = Color(0xFF171717);
  static const Color surfaceInteractive = Color(0xFF1E1E1E);
  static const Color borderSubtle = Color(0xFF292929);
  static const Color borderStrong = Color(0xFF3A3A3A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF858585);
  static const Color textDisabled = Color(0xFF626262);

  // --- Neutral Status & Feedback Tokens (Shapes & Contrast, No Colors) ---
  static const Color statusNeutralBg = Color(0xFF171717);
  static const Color statusNeutralBorder = Color(0xFF2E2E2E);
  static const Color statusNeutralText = Color(0xFFFFFFFF);

  // --- Light Mode Monochrome Counterparts ---
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
