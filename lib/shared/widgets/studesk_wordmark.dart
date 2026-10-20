import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

/// Distinctive, elegant editorial display wordmark for StuDesk.
/// Inspired by the visual elegance and refined curvature of editorial display serif branding.
class StuDeskWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final bool showDot;

  const StuDeskWordmark({
    super.key,
    this.fontSize = 22,
    this.color,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final textColor = color ?? stuTheme.textPrimary;

    return Semantics(
      label: 'StuDesk',
      header: true,
      child: RichText(
        text: TextSpan(
          text: 'StuDesk',
          style: GoogleFonts.fraunces(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: -0.8,
            fontStyle: FontStyle.normal,
          ),
          children: showDot
              ? [
                  TextSpan(
                    text: '.',
                    style: TextStyle(
                      color: stuTheme.accent,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
