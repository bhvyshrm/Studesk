import 'package:flutter/material.dart';

import '../data/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const AuthScreen({super.key, this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService.instance;

  static const Color _bgAmoled = Color(0xFF000000);
  static const Color _surfaceTier1 = Color(0xFF0E0E11);
  static const Color _surfaceTier2 = Color(0xFF17171C);
  static const Color _borderNeutral = Color(0xFF26262F);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFA0A0AD);
  static const Color _textMuted = Color(0xFF6E6E7A);

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
    if (_authService.isAuthenticated) {
      widget.onAuthenticated?.call();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final started = await _authService.signInWithGoogle();
      if (started && mounted) {
        if (_authService.isAuthenticated) {
          widget.onAuthenticated?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _surfaceTier2,
            content: Text(
              'Sign-in error: $e',
              style: const TextStyle(color: _textPrimary),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticating = _authService.status == AuthStatus.authenticating;
    final isConfigured = _authService.isBackendConfigured;

    return Scaffold(
      backgroundColor: _bgAmoled,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Logo
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _surfaceTier1,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _borderNeutral),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/studesk_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.school_rounded,
                                color: _textPrimary,
                                size: 40,
                              ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'StuDesk',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Your Intelligent Student Workspace & Academic Desk',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSecondary,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Supabase Cloud Status Card (Monochrome)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceTier1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _borderNeutral),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _surfaceTier2,
                            shape: BoxShape.circle,
                            border: Border.all(color: _borderNeutral),
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: _textPrimary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConfigured
                                    ? 'Google OAuth via Supabase Cloud'
                                    : 'Supabase Configuration Missing',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isConfigured
                                    ? 'Sign in with your Google account to sync your academic desk, timetable, syllabus, and study resources.'
                                    : 'Supply SUPABASE_URL and SUPABASE_ANON_KEY to enable Google OAuth sign-in.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Banner (Monochrome)
                  if (_authService.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _surfaceTier1,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4A3535)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: _textPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _authService.errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFEEEEEE),
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: _textSecondary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _authService.clearError(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Continue with Google Button (The Only Supported Method)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _textPrimary,
                        foregroundColor: const Color(0xFF000000),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: const Color(0xFF222228),
                      ),
                      onPressed: (isAuthenticating || !isConfigured)
                          ? null
                          : _handleGoogleSignIn,
                      child: isAuthenticating
                          ? const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: _textMuted,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Connecting to Google...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF000000),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'G',
                                      style: TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF000000),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: _textMuted,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Protected by PostgreSQL Row Level Security (RLS)',
                          style: TextStyle(fontSize: 11, color: _textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
