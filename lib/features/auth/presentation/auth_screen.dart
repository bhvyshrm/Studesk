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
    if (_authService.isAuthenticated || _authService.isDemoMode) {
      widget.onAuthenticated?.call();
    }
  }

  void _handleGoogleSignIn() async {
    final success = await _authService.signInWithGoogle();
    if (success && mounted) {
      widget.onAuthenticated?.call();
    }
  }

  void _handleContinueAsGuest() {
    _authService.enterDemoMode();
    widget.onAuthenticated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final stuTheme = context.stuTheme;
    final isAuthenticating = _authService.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: stuTheme.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier1,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: stuTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/images/studesk_logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.school_rounded,
                      color: stuTheme.accent,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'StuDesk',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: stuTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Academic Companion & Intelligent Desk',
                  style: TextStyle(
                    fontSize: 14,
                    color: stuTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // Environment / Backend status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: stuTheme.surfaceTier1,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: stuTheme.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _authService.isBackendConfigured
                            ? Icons.cloud_done_rounded
                            : Icons.offline_bolt_rounded,
                        color: _authService.isBackendConfigured
                            ? stuTheme.success
                            : stuTheme.accent,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _authService.isBackendConfigured
                                  ? 'Supabase Cloud Connected'
                                  : 'Offline / Local Companion Mode',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: stuTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _authService.isBackendConfigured
                                  ? 'PostgreSQL backend with Row-Level Security active.'
                                  : 'Local data persistence enabled without external credentials.',
                              style: TextStyle(
                                fontSize: 11,
                                color: stuTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_authService.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: stuTheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: stuTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _authService.errorMessage!,
                      style: TextStyle(color: stuTheme.error, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stuTheme.surfaceTier2,
                      foregroundColor: stuTheme.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: stuTheme.border),
                      ),
                    ),
                    onPressed: isAuthenticating ? null : _handleGoogleSignIn,
                    child: isAuthenticating
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: stuTheme.accent,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.g_mobiledata_rounded,
                                  size: 28,
                                  color: stuTheme.accent,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // Continue in Demo/Local Mode Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stuTheme.accent,
                      foregroundColor: stuTheme.onAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _handleContinueAsGuest,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Continue in Local Student Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'End-to-end data isolation protected with PostgreSQL Row Level Security (RLS).',
                  style: TextStyle(
                    fontSize: 11,
                    color: stuTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
