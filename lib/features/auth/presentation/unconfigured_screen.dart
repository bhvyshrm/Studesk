import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_service.dart';

class UnconfiguredConfigScreen extends StatelessWidget {
  const UnconfiguredConfigScreen({super.key});

  static const String sampleCommand =
      'flutter run -d chrome --web-port 5001 \\\n'
      '  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \\\n'
      '  --dart-define=SUPABASE_ANON_KEY=<your-publishable-key>';

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: stuTheme.surfaceTier1,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: stuTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: stuTheme.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.build_circle_rounded,
                          color: stuTheme.accent,
                          size: 36,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Supabase Configuration Required',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: stuTheme.textPrimary,
                        letterSpacing: -0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'StuDesk requires your Supabase project credentials to enable Google OAuth and encrypted student profile synchronization.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: stuTheme.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Code block explaining build-time configuration
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: stuTheme.surfaceTier2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: stuTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Run with Build Arguments:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: stuTheme.accent,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copy command',
                                icon: Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: stuTheme.textSecondary,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    const ClipboardData(text: sampleCommand),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: stuTheme.surfaceTier3,
                                      content: Text(
                                        'Command copied to clipboard',
                                        style: TextStyle(
                                          color: stuTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            sampleCommand,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: stuTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Retry button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stuTheme.accent,
                          foregroundColor: stuTheme.onAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          AuthService.instance.init();
                        },
                        child: const Text(
                          'Retry Connection',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
