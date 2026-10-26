import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/studesk_wordmark.dart';
import '../../profile/data/profile_service.dart';
import '../data/auth_service.dart';

enum _AuthMode { login, register, forgotPassword }

enum _UsernameStatus { idle, checking, available, taken, invalid, reserved }

/// StuDesk Production-Grade Authentication Screen.
///
/// Refined AMOLED dark aesthetic:
/// - True obsidian black background (#000000) with subtle ambient depth
/// - Layered surface elevation (#0C0C12, #13131A, #181822)
/// - Crisp hairline borders (#22222E, #DCDCE8 on focus)
/// - High-contrast tactile primary buttons (#FFFFFF on #000000)
/// - Real-time responsive validation feedback
/// - Fully responsive for mobile and desktop viewports
/// - Zero external backend or database implementation leaks
class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const AuthScreen({super.key, this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService.instance;
  final ProfileService _profileService = ProfileService.instance;

  _AuthMode _mode = _AuthMode.login;

  // Controllers - Login
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Controllers - Register
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  // Controllers - Forgot Password
  final _forgotIdentifierController = TextEditingController();

  // Focus Nodes
  final _loginUsernameFocus = FocusNode();
  final _loginPasswordFocus = FocusNode();
  final _registerUsernameFocus = FocusNode();
  final _registerEmailFocus = FocusNode();
  final _registerPasswordFocus = FocusNode();
  final _registerConfirmFocus = FocusNode();
  final _forgotIdentifierFocus = FocusNode();

  // Password visibility
  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureRegisterConfirmPassword = true;

  // Real-time username check state (Registration)
  Timer? _usernameDebounceTimer;
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;
  String? _usernameStatusMessage;

  // State flags
  bool _isSubmitting = false;
  String? _localErrorMessage;
  String? _successBannerMessage;

  // Refined AMOLED Monochrome Palette
  static const Color _bgAmoled = Color(0xFF000000);
  static const Color _surfaceCard = Color(0xFF0C0C12);
  static const Color _surfaceInput = Color(0xFF13131A);
  static const Color _surfaceInputHover = Color(0xFF171722);
  static const Color _borderNeutral = Color(0xFF22222E);
  static const Color _borderFocus = Color(0xFFDCDCE8);
  static const Color _borderError = Color(0xFF5A252B);
  static const Color _bannerErrorBg = Color(0xFF1A1012);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFA0A0B0);
  static const Color _textMuted = Color(0xFF686878);

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthServiceChanged);
    _registerUsernameController.addListener(_onRegisterUsernameChanged);

    // Rebuild when focus changes to update input border highlighting
    _loginUsernameFocus.addListener(_onFocusChanged);
    _loginPasswordFocus.addListener(_onFocusChanged);
    _registerUsernameFocus.addListener(_onFocusChanged);
    _registerEmailFocus.addListener(_onFocusChanged);
    _registerPasswordFocus.addListener(_onFocusChanged);
    _registerConfirmFocus.addListener(_onFocusChanged);
    _forgotIdentifierFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _usernameDebounceTimer?.cancel();
    _authService.removeListener(_onAuthServiceChanged);

    _loginUsernameFocus.removeListener(_onFocusChanged);
    _loginPasswordFocus.removeListener(_onFocusChanged);
    _registerUsernameFocus.removeListener(_onFocusChanged);
    _registerEmailFocus.removeListener(_onFocusChanged);
    _registerPasswordFocus.removeListener(_onFocusChanged);
    _registerConfirmFocus.removeListener(_onFocusChanged);
    _forgotIdentifierFocus.removeListener(_onFocusChanged);

    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.removeListener(_onRegisterUsernameChanged);
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _forgotIdentifierController.dispose();

    _loginUsernameFocus.dispose();
    _loginPasswordFocus.dispose();
    _registerUsernameFocus.dispose();
    _registerEmailFocus.dispose();
    _registerPasswordFocus.dispose();
    _registerConfirmFocus.dispose();
    _forgotIdentifierFocus.dispose();

    super.dispose();
  }

  void _onAuthServiceChanged() {
    if (mounted) {
      if (_authService.statusMessage != null) {
        _successBannerMessage = _authService.statusMessage;
      }
      setState(() {});
    }
    if (_authService.isAuthenticated) {
      widget.onAuthenticated?.call();
    }
  }

  void _switchMode(_AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _localErrorMessage = null;
      _successBannerMessage = null;
      _authService.clearError();
    });
  }

  void _onRegisterUsernameChanged() {
    final raw = _registerUsernameController.text;
    final lower = raw.toLowerCase().replaceAll(' ', '_');
    if (raw != lower) {
      final selection = _registerUsernameController.selection;
      _registerUsernameController.value = _registerUsernameController.value
          .copyWith(text: lower, selection: selection);
      return;
    }

    _usernameDebounceTimer?.cancel();
    final trimmed = lower.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _usernameStatus = _UsernameStatus.idle;
        _usernameStatusMessage = null;
      });
      return;
    }

    final validationError = _profileService.validateUsername(trimmed);
    if (validationError != null) {
      setState(() {
        _usernameStatus = validationError.contains('reserved')
            ? _UsernameStatus.reserved
            : _UsernameStatus.invalid;
        _usernameStatusMessage = validationError;
      });
      return;
    }

    setState(() {
      _usernameStatus = _UsernameStatus.checking;
      _usernameStatusMessage = 'Checking availability...';
    });

    _usernameDebounceTimer = Timer(const Duration(milliseconds: 320), () async {
      final isAvailable = await _profileService.checkUsernameAvailable(trimmed);
      if (!mounted ||
          _registerUsernameController.text.trim().toLowerCase() != trimmed) {
        return;
      }

      setState(() {
        if (isAvailable) {
          _usernameStatus = _UsernameStatus.available;
          _usernameStatusMessage = '@$trimmed is available';
        } else {
          _usernameStatus = _UsernameStatus.taken;
          _usernameStatusMessage =
              '@$trimmed is already taken by another student';
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------

  Future<void> _handleLogin() async {
    if (_isSubmitting) return;

    final username = _loginUsernameController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (username.isEmpty) {
      setState(() => _localErrorMessage = 'Please enter your username.');
      return;
    }

    if (password.isEmpty) {
      setState(() => _localErrorMessage = 'Please enter your password.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localErrorMessage = null;
      _successBannerMessage = null;
    });

    try {
      final success = await _authService.signInWithUsernameAndPassword(
        username: username,
        password: password,
      );

      if (success && mounted) {
        widget.onAuthenticated?.call();
      } else if (mounted) {
        setState(() {
          _localErrorMessage =
              _authService.errorMessage ??
              'Invalid username or password. Please check your credentials.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_isSubmitting) return;

    final username = _registerUsernameController.text.trim().toLowerCase();
    final email = _registerEmailController.text.trim().toLowerCase();
    final password = _registerPasswordController.text.trim();
    final confirmPassword = _registerConfirmPasswordController.text.trim();

    // 1. Username validation
    final usernameError = _profileService.validateUsername(username);
    if (usernameError != null) {
      setState(() => _localErrorMessage = usernameError);
      return;
    }

    // 2. Email format validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(
        () => _localErrorMessage = 'Please enter a valid email address.',
      );
      return;
    }

    // 3. Password strength validation
    if (password.length < 6) {
      setState(
        () =>
            _localErrorMessage = 'Password must be at least 6 characters long.',
      );
      return;
    }

    // 4. Confirm password equality
    if (password != confirmPassword) {
      setState(() => _localErrorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localErrorMessage = null;
      _successBannerMessage = null;
    });

    try {
      final result = await _authService.signUpWithUsernameAndPassword(
        username: username,
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result.success) {
        if (result.requiresEmailVerification) {
          _switchMode(_AuthMode.login);
          setState(() {
            _successBannerMessage =
                'Account created! We sent a confirmation link to ${result.email ?? email}. Please check your inbox and verify your email before signing in.';
          });
        } else {
          widget.onAuthenticated?.call();
        }
      } else {
        setState(() {
          _localErrorMessage =
              result.errorMessage ??
              'Account creation could not be completed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final identifier = _forgotIdentifierController.text.trim();
    if (identifier.isEmpty) {
      setState(
        () =>
            _localErrorMessage = 'Please enter your username or email address.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localErrorMessage = null;
      _successBannerMessage = null;
    });

    try {
      final message = await _authService.sendPasswordResetEmail(
        identifier: identifier,
      );
      if (mounted) {
        setState(() {
          _successBannerMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localErrorMessage = 'Unable to send reset link. Please check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build Methods
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgAmoled,
      body: Stack(
        children: [
          // Subtle ambient glow at top center for visual depth on desktop and mobile
          Positioned(
            top: -120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 520,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1A1A28).withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // StuDesk Hero Brand Header
                      _buildBrandingHeader(),

                      const SizedBox(height: 24),

                      // Success Banner
                      if (_successBannerMessage != null) ...[
                        _buildSuccessBanner(_successBannerMessage!),
                        const SizedBox(height: 14),
                      ],

                      // Error Banner
                      if (_localErrorMessage != null ||
                          _authService.errorMessage != null) ...[
                        _buildErrorBanner(
                          _localErrorMessage ?? _authService.errorMessage!,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Main Authentication Card
                      _buildCardContainer(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: switch (_mode) {
                            _AuthMode.login => KeyedSubtree(
                              key: const ValueKey('login_form_view'),
                              child: _buildLoginForm(),
                            ),
                            _AuthMode.register => KeyedSubtree(
                              key: const ValueKey('register_form_view'),
                              child: _buildRegisterForm(),
                            ),
                            _AuthMode.forgotPassword => KeyedSubtree(
                              key: const ValueKey('forgot_password_view'),
                              child: _buildForgotPasswordForm(),
                            ),
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Student Security Trust Footer (Zero Backend Implementation Leaks)
                      _buildSecurityFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingHeader() {
    return Column(
      children: [
        // App Crest Icon
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: _surfaceCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderNeutral, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(15),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/studesk_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.school_rounded,
                color: _textPrimary,
                size: 38,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // StuDesk Editorial Wordmark
        const StuDeskWordmark(fontSize: 30, showDot: true),

        const SizedBox(height: 6),

        // App Tagline
        const Text(
          'Your Intelligent Student Workspace & Academic Desk',
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
            letterSpacing: -0.1,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderNeutral, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  // ---------------------------------------------------------------------------
  // View 1: Login Form
  // ---------------------------------------------------------------------------

  Widget _buildLoginForm() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Enter your student username and password to continue.',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 22),

          // Username Field
          _buildFieldLabel('STUDENT USERNAME'),
          const SizedBox(height: 8),
          _buildInputWrapper(
            isFocused: _loginUsernameFocus.hasFocus,
            child: TextField(
              controller: _loginUsernameController,
              focusNode: _loginUsernameFocus,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              autofillHints: const [AutofillHints.username],
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: _buildInputDecoration(
                hintText: 'alex_chen',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Text(
                    '@',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              onSubmitted: (_) => _loginPasswordFocus.requestFocus(),
            ),
          ),

          const SizedBox(height: 18),

          // Password Field Header with Forgot password action
          Row(
            children: [
              Expanded(child: _buildFieldLabel('PASSWORD')),
              GestureDetector(
                onTap: () => _switchMode(_AuthMode.forgotPassword),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInputWrapper(
            isFocused: _loginPasswordFocus.hasFocus,
            child: TextField(
              controller: _loginPasswordController,
              focusNode: _loginPasswordFocus,
              obscureText: _obscureLoginPassword,
              autofillHints: const [AutofillHints.password],
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              decoration: _buildInputDecoration(
                hintText: '••••••••',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: _textMuted,
                    size: 18,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _textSecondary,
                    size: 19,
                  ),
                  onPressed: () => setState(
                    () => _obscureLoginPassword = !_obscureLoginPassword,
                  ),
                ),
              ),
              onSubmitted: (_) {
                if (!_isSubmitting) _handleLogin();
              },
            ),
          ),

          const SizedBox(height: 24),

          // Primary Sign In Button
          _buildPrimaryButton(
            label: 'Sign In',
            isLoading: _isSubmitting,
            onPressed: _handleLogin,
          ),

          const SizedBox(height: 20),

          // Bottom Toggle to Register
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(fontSize: 13, color: _textSecondary),
              ),
              GestureDetector(
                onTap: () => _switchMode(_AuthMode.register),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View 2: Registration Form
  // ---------------------------------------------------------------------------

  Widget _buildRegisterForm() {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Set up your student profile and secure credentials.',
            style: TextStyle(fontSize: 13, color: _textSecondary),
          ),
          const SizedBox(height: 20),

          // 1. Username Field
          _buildFieldLabel('CHOOSE USERNAME'),
          const SizedBox(height: 8),
          _buildInputWrapper(
            isFocused: _registerUsernameFocus.hasFocus,
            child: TextField(
              controller: _registerUsernameController,
              focusNode: _registerUsernameFocus,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              keyboardType: TextInputType.text,
              autofillHints: const [AutofillHints.newUsername],
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: _buildInputDecoration(
                hintText: 'alex_chen',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Text(
                    '@',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                suffixIcon: _buildUsernameStatusSuffix(),
              ),
              onSubmitted: (_) => _registerEmailFocus.requestFocus(),
            ),
          ),

          if (_usernameStatusMessage != null) ...[
            const SizedBox(height: 8),
            _buildUsernameStatusBanner(),
          ],

          const SizedBox(height: 5),
          const Text(
            '3–20 lowercase letters, numbers, and underscores only.',
            style: TextStyle(fontSize: 11, color: _textMuted),
          ),

          const SizedBox(height: 16),

          // 2. Email Field
          _buildFieldLabel('EMAIL ADDRESS'),
          const SizedBox(height: 8),
          _buildInputWrapper(
            isFocused: _registerEmailFocus.hasFocus,
            child: TextField(
              controller: _registerEmailController,
              focusNode: _registerEmailFocus,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              decoration: _buildInputDecoration(
                hintText: 'student@university.edu',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Icon(
                    Icons.alternate_email_rounded,
                    color: _textMuted,
                    size: 18,
                  ),
                ),
              ),
              onSubmitted: (_) => _registerPasswordFocus.requestFocus(),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Password Field
          _buildFieldLabel('PASSWORD'),
          const SizedBox(height: 8),
          _buildInputWrapper(
            isFocused: _registerPasswordFocus.hasFocus,
            child: TextField(
              controller: _registerPasswordController,
              focusNode: _registerPasswordFocus,
              obscureText: _obscureRegisterPassword,
              autofillHints: const [AutofillHints.newPassword],
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              decoration: _buildInputDecoration(
                hintText: 'At least 6 characters',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: _textMuted,
                    size: 18,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRegisterPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _textSecondary,
                    size: 19,
                  ),
                  onPressed: () => setState(
                    () => _obscureRegisterPassword = !_obscureRegisterPassword,
                  ),
                ),
              ),
              onSubmitted: (_) => _registerConfirmFocus.requestFocus(),
            ),
          ),

          const SizedBox(height: 16),

          // 4. Confirm Password Field
          _buildFieldLabel('CONFIRM PASSWORD'),
          const SizedBox(height: 8),
          _buildInputWrapper(
            isFocused: _registerConfirmFocus.hasFocus,
            child: TextField(
              controller: _registerConfirmPasswordController,
              focusNode: _registerConfirmFocus,
              obscureText: _obscureRegisterConfirmPassword,
              style: const TextStyle(color: _textPrimary, fontSize: 15),
              decoration: _buildInputDecoration(
                hintText: 'Re-enter your password',
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: _textMuted,
                    size: 18,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureRegisterConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _textSecondary,
                    size: 19,
                  ),
                  onPressed: () => setState(
                    () => _obscureRegisterConfirmPassword =
                        !_obscureRegisterConfirmPassword,
                  ),
                ),
              ),
              onSubmitted: (_) {
                if (!_isSubmitting) _handleRegister();
              },
            ),
          ),

          const SizedBox(height: 24),

          // Primary Create Account Button
          _buildPrimaryButton(
            label: 'Create Account',
            isLoading: _isSubmitting,
            onPressed: _handleRegister,
          ),

          const SizedBox(height: 20),

          // Bottom Toggle to Sign In
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(fontSize: 13, color: _textSecondary),
              ),
              GestureDetector(
                onTap: () => _switchMode(_AuthMode.login),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View 3: Forgot Password Form
  // ---------------------------------------------------------------------------

  Widget _buildForgotPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => _switchMode(_AuthMode.login),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _surfaceInput,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _borderNeutral),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _textPrimary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Enter your student username or registered email address. If an account is found, we will send password recovery instructions.',
          style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('USERNAME OR EMAIL'),
        const SizedBox(height: 8),
        _buildInputWrapper(
          isFocused: _forgotIdentifierFocus.hasFocus,
          child: TextField(
            controller: _forgotIdentifierController,
            focusNode: _forgotIdentifierFocus,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(color: _textPrimary, fontSize: 15),
            decoration: _buildInputDecoration(
              hintText: 'alex_chen or alex@university.edu',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 8),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _textMuted,
                  size: 19,
                ),
              ),
            ),
            onSubmitted: (_) {
              if (!_isSubmitting) _handleForgotPassword();
            },
          ),
        ),

        const SizedBox(height: 24),

        _buildPrimaryButton(
          label: 'Send Reset Link',
          isLoading: _isSubmitting,
          onPressed: _handleForgotPassword,
        ),

        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => _switchMode(_AuthMode.login),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable Component Helpers
  // ---------------------------------------------------------------------------

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: _textMuted,
      ),
    );
  }

  Widget _buildInputWrapper({required Widget child, required bool isFocused}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: isFocused ? _surfaceInputHover : _surfaceInput,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isFocused ? _borderFocus : _borderNeutral,
          width: isFocused ? 1.2 : 1.0,
        ),
      ),
      child: child,
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF505060),
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffixIcon,
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _textPrimary,
          foregroundColor: const Color(0xFF000000),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          disabledBackgroundColor: const Color(0xFF1E1E26),
          disabledForegroundColor: _textMuted,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFF000000),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  Widget? _buildUsernameStatusSuffix() {
    switch (_usernameStatus) {
      case _UsernameStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _textSecondary,
            ),
          ),
        );
      case _UsernameStatus.available:
        return const Icon(
          Icons.check_circle_rounded,
          color: _textPrimary,
          size: 18,
        );
      case _UsernameStatus.taken:
      case _UsernameStatus.reserved:
      case _UsernameStatus.invalid:
        return const Icon(
          Icons.cancel_rounded,
          color: _textSecondary,
          size: 18,
        );
      case _UsernameStatus.idle:
        return null;
    }
  }

  Widget _buildUsernameStatusBanner() {
    IconData icon;
    Color iconColor;
    Color textColor;

    switch (_usernameStatus) {
      case _UsernameStatus.available:
        icon = Icons.check_circle_rounded;
        iconColor = _textPrimary;
        textColor = _textPrimary;
        break;
      case _UsernameStatus.taken:
      case _UsernameStatus.reserved:
      case _UsernameStatus.invalid:
        icon = Icons.info_outline_rounded;
        iconColor = _textSecondary;
        textColor = _textSecondary;
        break;
      case _UsernameStatus.checking:
        icon = Icons.hourglass_top_rounded;
        iconColor = _textMuted;
        textColor = _textMuted;
        break;
      case _UsernameStatus.idle:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _surfaceInput,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderNeutral),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _usernameStatusMessage ?? '',
              style: TextStyle(
                fontSize: 11.5,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _bannerErrorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderError),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1.5),
            child: Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDDDDDD),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFEEEEEE),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _localErrorMessage = null);
              _authService.clearError();
            },
            child: const Icon(Icons.close, size: 16, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1511),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF223628)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1.5),
            child: Icon(
              Icons.check_circle_outline_rounded,
              color: _textPrimary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _successBannerMessage = null),
            child: const Icon(Icons.close, size: 16, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return const FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 13, color: _textMuted),
          SizedBox(width: 6),
          Text(
            'Secure & Private Student Workspace',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
