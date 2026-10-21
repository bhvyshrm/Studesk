import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final Widget? leadingIndicator;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 20.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.leadingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final bg = backgroundColor ?? stuTheme.surfaceTier1;
    final border = borderColor ?? stuTheme.border;

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            if (leadingIndicator != null)
              Positioned(left: 0, top: 0, bottom: 0, child: leadingIndicator!),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
