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

  static const light = StuDeskThemeExtension(
    canvas: AppColors.lightCanvas,
    surfaceTier1: AppColors.lightSurface,
    surfaceTier2: AppColors.lightSurfaceSecondary,
    surfaceTier3: AppColors.lightSurfaceHigh,
    border: AppColors.lightBorder,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    accent: AppColors.goldLight,
    onAccent: AppColors.lightTextPrimary,
    success: AppColors.lightSuccess,
    successContainer: AppColors.lightSuccessContainer,
    warning: AppColors.lightWarning,
    warningContainer: AppColors.lightWarningContainer,
    error: AppColors.lightError,
    errorContainer: AppColors.lightErrorContainer,
    isAmoled: false,
  );

  static const dark = StuDeskThemeExtension(
    canvas: AppColors.darkCanvas,
    surfaceTier1: AppColors.darkSurfaceTier1,
    surfaceTier2: AppColors.darkSurfaceTier2,
    surfaceTier3: AppColors.darkSurfaceTier3,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textMuted: AppColors.darkTextMuted,
    accent: AppColors.goldDark,
    onAccent: Color(0xFF000000),
    success: AppColors.darkSuccess,
    successContainer: AppColors.darkSuccessContainer,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningContainer,
    error: AppColors.darkError,
    errorContainer: AppColors.darkErrorContainer,
    isAmoled: false,
  );

  static const amoled = StuDeskThemeExtension(
    canvas: AppColors.amoledCanvas,
    surfaceTier1: AppColors.amoledSurfaceTier1,
    surfaceTier2: AppColors.amoledSurfaceTier2,
    surfaceTier3: AppColors.amoledSurfaceTier3,
    border: AppColors.amoledBorder,
    textPrimary: AppColors.amoledTextPrimary,
    textSecondary: AppColors.amoledTextSecondary,
    textMuted: AppColors.amoledTextMuted,
    accent: AppColors.goldDark,
    onAccent: Color(0xFF000000),
    success: AppColors.darkSuccess,
    successContainer: AppColors.darkSuccessContainer,
    warning: AppColors.darkWarning,
    warningContainer: AppColors.darkWarningContainer,
    error: AppColors.darkError,
    errorContainer: AppColors.darkErrorContainer,
    isAmoled: true,
  );
}

extension BuildContextThemeExt on BuildContext {
  StuDeskThemeExtension get stuTheme =>
      Theme.of(this).extension<StuDeskThemeExtension>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? StuDeskThemeExtension.dark
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
        primary: AppColors.goldLight,
        onPrimary: AppColors.lightTextPrimary,
        secondary: AppColors.goldLight,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.lightError,
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
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
      scaffoldBackgroundColor: AppColors.darkCanvas,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseText),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldDark,
        onPrimary: Color(0xFF000000),
        secondary: AppColors.goldDark,
        surface: AppColors.darkSurfaceTier1,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.darkError,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceTier1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
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
      scaffoldBackgroundColor: AppColors.amoledCanvas,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(baseText),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldDark,
        onPrimary: Color(0xFF000000),
        secondary: AppColors.goldDark,
        surface: AppColors.amoledSurfaceTier1,
        onSurface: AppColors.amoledTextPrimary,
        error: AppColors.darkError,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.amoledCanvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: AppColors.amoledTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.amoledSurfaceTier1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.amoledBorder, width: 1),
        ),
      ),
      extensions: const [StuDeskThemeExtension.amoled],
    );
  }
}
