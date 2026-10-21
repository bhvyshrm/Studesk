import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const AuthScreen({super.key, this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService.instance;

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
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('Authentication error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final isAuthenticating = _authService.status == AuthStatus.authenticating;
    final isConfigured = _authService.isBackendConfigured;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
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
                        color: stuTheme.surfaceTier1,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: stuTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(14),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/studesk_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.school_rounded,
                            color: stuTheme.accent,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'StuDesk',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: stuTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your Intelligent Student Workspace & Academic Desk',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: stuTheme.textSecondary,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // Supabase Cloud Status Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: stuTheme.surfaceTier1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: stuTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                (isConfigured
                                        ? stuTheme.success
                                        : stuTheme.accent)
                                    .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isConfigured
                                ? Icons.verified_user_rounded
                                : Icons.settings_ethernet_rounded,
                            color: isConfigured
                                ? stuTheme.success
                                : stuTheme.accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isConfigured
                                    ? 'Supabase Cloud Authentication'
                                    : 'Supabase Configuration Missing',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: stuTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isConfigured
                                    ? 'Sign in with your Google account to sync your academic desk, timetable, syllabus, and study resources.'
                                    : 'Supply SUPABASE_URL and SUPABASE_ANON_KEY to enable Google OAuth sign-in.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: stuTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error Banner
                  if (_authService.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: stuTheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: stuTheme.error.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: stuTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _authService.errorMessage!,
                              style: TextStyle(
                                color: stuTheme.error,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: stuTheme.error,
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
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stuTheme.surfaceTier2,
                        foregroundColor: stuTheme.textPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isAuthenticating
                                ? stuTheme.accent
                                : stuTheme.border,
                            width: isAuthenticating ? 1.5 : 1.0,
                          ),
                        ),
                        disabledBackgroundColor: stuTheme.surfaceTier2
                            .withValues(alpha: 0.6),
                      ),
                      onPressed: (isAuthenticating || !isConfigured)
                          ? null
                          : _handleGoogleSignIn,
                      child: isAuthenticating
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: stuTheme.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Connecting to Google...',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: stuTheme.textSecondary,
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
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: stuTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Protected by PostgreSQL Row Level Security (RLS)',
                          style: TextStyle(
                            fontSize: 11,
                            color: stuTheme.textMuted,
                          ),
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
