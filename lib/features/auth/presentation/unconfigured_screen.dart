import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_service.dart';

class UnconfiguredConfigScreen extends StatelessWidget {
  const UnconfiguredConfigScreen({super.key});

  static const String sampleCommand =
      'flutter run -d chrome --web-port 5001 \\\n'
      '  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \\\n'
      '  --dart-define=SUPABASE_ANON_KEY=<your-publishable-key>';

  static const Color _bgAmoled = Color(0xFF000000);
  static const Color _surfaceTier1 = Color(0xFF0E0E11);
  static const Color _surfaceTier2 = Color(0xFF17171C);
  static const Color _surfaceTier3 = Color(0xFF222228);
  static const Color _borderNeutral = Color(0xFF26262F);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFA0A0AD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgAmoled,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _surfaceTier1,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _borderNeutral),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
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
                          color: _surfaceTier2,
                          shape: BoxShape.circle,
                          border: Border.all(color: _borderNeutral),
                        ),
                        child: const Icon(
                          Icons.build_circle_rounded,
                          color: _textPrimary,
                          size: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Connection Configuration Required',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                        letterSpacing: -0.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'StuDesk requires your server connection credentials to enable student authentication and encrypted profile synchronization.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Code block explaining build-time configuration
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surfaceTier2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderNeutral),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Run with Build Arguments:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copy command',
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: _textSecondary,
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    const ClipboardData(text: sampleCommand),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      backgroundColor: _surfaceTier3,
                                      content: Text(
                                        'Command copied to clipboard',
                                        style: TextStyle(color: _textPrimary),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const SelectableText(
                            sampleCommand,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: _textSecondary,
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
                          backgroundColor: _textPrimary,
                          foregroundColor: const Color(0xFF000000),
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
