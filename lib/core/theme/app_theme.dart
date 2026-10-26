import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

@immutable
class StuDeskThemeExtension extends ThemeExtension<StuDeskThemeExtension> {
  final Color canvas;
  final Color surfaceTier1;
  final Color surfaceTier2;
  final Color surfaceTier3;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color error;
  final Color errorContainer;
  final bool isAmoled;

  const StuDeskThemeExtension({
    required this.canvas,
    required this.surfaceTier1,
    required this.surfaceTier2,
    required this.surfaceTier3,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.error,
    required this.errorContainer,
    this.isAmoled = false,
  });

  @override
  StuDeskThemeExtension copyWith({
    Color? canvas,
    Color? surfaceTier1,
    Color? surfaceTier2,
    Color? surfaceTier3,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? error,
    Color? errorContainer,
    bool? isAmoled,
  }) {
    return StuDeskThemeExtension(
      canvas: canvas ?? this.canvas,
      surfaceTier1: surfaceTier1 ?? this.surfaceTier1,
      surfaceTier2: surfaceTier2 ?? this.surfaceTier2,
      surfaceTier3: surfaceTier3 ?? this.surfaceTier3,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      error: error ?? this.error,
      errorContainer: errorContainer ?? this.errorContainer,
      isAmoled: isAmoled ?? this.isAmoled,
    );
  }

  @override
  StuDeskThemeExtension lerp(
    ThemeExtension<StuDeskThemeExtension>? other,
    double t,
  ) {
    if (other is! StuDeskThemeExtension) return this;
    return StuDeskThemeExtension(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surfaceTier1: Color.lerp(surfaceTier1, other.surfaceTier1, t)!,
      surfaceTier2: Color.lerp(surfaceTier2, other.surfaceTier2, t)!,
      surfaceTier3: Color.lerp(surfaceTier3, other.surfaceTier3, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      error: Color.lerp(error, other.error, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
      isAmoled: t < 0.5 ? isAmoled : other.isAmoled,
    );
  }

  // --- Strict Monochrome Light Theme Extension ---
  static const light = StuDeskThemeExtension(
    canvas: AppColors.lightCanvas,
    surfaceTier1: AppColors.lightSurface,
    surfaceTier2: AppColors.lightSurfaceSecondary,
    surfaceTier3: AppColors.lightSurfaceHigh,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    accent: Color(0xFF000000),
    onAccent: Color(0xFFFFFFFF),
    success: AppColors.lightTextPrimary,
    successContainer: AppColors.lightSurfaceSecondary,
    warning: AppColors.lightTextSecondary,
    warningContainer: AppColors.lightSurfaceSecondary,
    error: AppColors.lightTextPrimary,
    errorContainer: AppColors.lightSurfaceHigh,
    isAmoled: false,
  );

  // --- Strict Monochrome Refined Charcoal Dark Theme Extension ---
  static const dark = StuDeskThemeExtension(
    canvas: AppColors.elevatedBg,
    surfaceTier1: AppColors.surfaceSecondary,
    surfaceTier2: AppColors.surfaceElevated,
    surfaceTier3: AppColors.surfaceInteractive,
    border: AppColors.borderSubtle,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    success: AppColors.textPrimary,
    successContainer: AppColors.surfaceElevated,
    warning: AppColors.textSecondary,
    warningContainer: AppColors.surfaceElevated,
    error: AppColors.textPrimary,
    errorContainer: AppColors.surfaceInteractive,
    isAmoled: false,
  );

  // --- Strict Monochrome AMOLED True-Black Theme Extension ---
  static const amoled = StuDeskThemeExtension(
    canvas: AppColors.primaryBg,
    surfaceTier1: AppColors.surfaceSecondary,
    surfaceTier2: AppColors.surfaceElevated,
    surfaceTier3: AppColors.surfaceInteractive,
    border: AppColors.borderSubtle,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    accent: Color(0xFFFFFFFF),
    onAccent: Color(0xFF000000),
    success: AppColors.textPrimary,
    successContainer: AppColors.surfaceElevated,
    warning: AppColors.textSecondary,
    warningContainer: AppColors.surfaceElevated,
    error: AppColors.textPrimary,
    errorContainer: AppColors.surfaceInteractive,
    isAmoled: true,
  );
}

extension BuildContextThemeExt on BuildContext {
  StuDeskThemeExtension get stuTheme =>
      Theme.of(this).extension<StuDeskThemeExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? StuDeskThemeExtension.amoled
          : StuDeskThemeExtension.light);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseText = ThemeData.light().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightCanvas,
      textTheme: GoogleFonts.interTextTheme(baseText),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF000000),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF333333),
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: Color(0xFF000000),
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
      extensions: const [StuDeskThemeExtension.light],
    );
  }

  static ThemeData get darkTheme {
    final baseText = ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.elevatedBg,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseText),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFFE5E5E5),
        surface: AppColors.surfaceSecondary,
        onSurface: AppColors.textPrimary,
        error: Color(0xFFFFFFFF),
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.elevatedBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      extensions: const [StuDeskThemeExtension.dark],
    );
  }

  static ThemeData get amoledDarkTheme {
    final baseText = ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryBg,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseText),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFFE5E5E5),
        surface: AppColors.surfaceSecondary,
        onSurface: AppColors.textPrimary,
        error: Color(0xFFFFFFFF),
        onError: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      extensions: const [StuDeskThemeExtension.amoled],
    );
  }
}
