import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthSplashScreen extends StatelessWidget {
  const AuthSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: stuTheme.surfaceTier1,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: stuTheme.border),
              ),
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/studesk_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.school_rounded,
                    color: stuTheme.accent,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: stuTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
