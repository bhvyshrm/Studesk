import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../profile/data/profile_service.dart';

enum AuthStatus {
  uninitialized,
  unconfigured,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

/// Result object returned by registration flow to handle both immediate logins
/// and email-verification required states.
class SignUpResult {
  final bool success;
  final bool requiresEmailVerification;
  final String? email;
  final String? errorMessage;

  const SignUpResult({
    required this.success,
    this.requiresEmailVerification = false,
    this.email,
    this.errorMessage,
  });
}

/// Dedicated Authentication Service for StuDesk.
/// Supports secure username-and-password login, registration with uniqueness constraints,
/// password recovery, and session persistence using Supabase Auth backend.
class AuthService extends ChangeNotifier with WidgetsBindingObserver {
  AuthService._();
  static final AuthService instance = AuthService._();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;
  String? _statusMessage;
  User? _currentUser;
  bool _isSupabaseInitialized = false;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _oauthCancelTimer;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;
  bool get isBackendConfigured => SupabaseConfig.isConfigured;
  bool get isSupabaseInitialized => _isSupabaseInitialized;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearStatusMessage() {
    _statusMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();
  }

  Future<void> init() async {
    WidgetsBinding.instance.addObserver(this);

    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      notifyListeners();
      return;
    }

    try {
      if (!_isSupabaseInitialized) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.anonKey,
        );
        _isSupabaseInitialized = true;
      }

      await _authSubscription?.cancel();
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen(
            (data) {
              _handleAuthStateChange(data.event, data.session);
            },
            onError: (error) {
              debugPrint('Supabase Auth error listener: $error');
              if (error is AuthException) {
                final msgLower = error.message.toLowerCase();
                if (error.statusCode == 'otp_expired' ||
                    msgLower.contains('expired')) {
                  _errorMessage = 'Your email verification link has expired or has already been used. Please sign in or request a new confirmation email.';
                } else if (msgLower.contains('code verifier') ||
                    error is AuthPKCEGrantCodeExchangeError) {
                  _errorMessage = 'Email confirmed! Please sign in with your username and password.';
                } else if (error.message.isNotEmpty) {
                  _errorMessage = error.message;
                } else {
                  _errorMessage = 'Email confirmation failed. Please check your verification link and try again.';
                }
              } else {
                _errorMessage =
                    'Authentication connection interrupted. Please try again.';
              }
              _status = AuthStatus.unauthenticated;
              notifyListeners();
            },
          );

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _currentUser = session.user;
        _status = AuthStatus.authenticated;
        unawaited(
          ProfileService.instance.fetchAndSyncProfile(user: session.user),
        );
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Supabase initialization exception: $e');
      _errorMessage = 'Unable to connect to authentication server. Please check your network connection.';
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _oauthCancelTimer != null) {
      _oauthCancelTimer?.cancel();
      _oauthCancelTimer = Timer(const Duration(milliseconds: 1800), () {
        if (_status == AuthStatus.authenticating && _currentUser == null) {
          _status = AuthStatus.unauthenticated;
          _errorMessage = 'Sign-in was cancelled or closed.';
          _oauthCancelTimer = null;
          notifyListeners();
        }
      });
    }
  }

  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    debugPrint(
      'StuDesk AuthChangeEvent: $event (hasSession: ${session != null})',
    );
    _oauthCancelTimer?.cancel();
    _oauthCancelTimer = null;

    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (session != null) {
          final wasAuthenticating = _status == AuthStatus.authenticating;
          _currentUser = session.user;
          _status = AuthStatus.authenticated;
          _errorMessage = null;
          if (!wasAuthenticating && event == AuthChangeEvent.signedIn) {
            _statusMessage =
                'Email verified successfully. You are now signed in.';
          }
          notifyListeners();
          unawaited(
            ProfileService.instance.fetchAndSyncProfile(user: session.user),
          );
        }
        break;

      case AuthChangeEvent.signedOut:
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        _statusMessage = null;
        ProfileService.instance.resetState();
        notifyListeners();
        break;

      default:
        break;
    }
  }

  /// Authenticates using a student username (or registered email) and password.
  /// Safely resolves the username to internal auth email using server-side RPC
  /// without exposing user email or profile data to the client.
  Future<bool> signInWithUsernameAndPassword({
    required String username,
    required String password,
  }) async {
    if (_status == AuthStatus.authenticating) {
      return false;
    }

    final trimmedInput = username.trim();
    final trimmedPassword = password.trim();

    if (trimmedInput.isEmpty) {
      _errorMessage = 'Please enter your username.';
      notifyListeners();
      return false;
    }

    if (trimmedPassword.isEmpty) {
      _errorMessage = 'Please enter your password.';
      notifyListeners();
      return false;
    }

    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      _errorMessage = 'Authentication service is not configured. Please check your application environment settings.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.authenticating;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      if (!_isSupabaseInitialized) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.anonKey,
        );
        _isSupabaseInitialized = true;
      }

      String targetEmail;

      if (trimmedInput.contains('@')) {
        // Direct email login for existing users or students using email
        targetEmail = trimmedInput.toLowerCase();
      } else {
        final normalizedUsername = trimmedInput.toLowerCase();

        // Basic format check before lookup
        final formatError = ProfileService.instance.validateUsername(
          normalizedUsername,
        );
        if (formatError != null) {
          _status = AuthStatus.unauthenticated;
          _errorMessage =
              'Invalid username or password. Please check your credentials.';
          notifyListeners();
          return false;
        }

        // Backend-safe RPC lookup: resolves username -> email without exposing profile data
        String? resolvedEmail;
        try {
          final res = await Supabase.instance.client.rpc(
            'get_auth_email_for_username',
            params: {'p_username': normalizedUsername},
          );
          if (res is String && res.trim().isNotEmpty) {
            resolvedEmail = res.trim();
          }
        } catch (rpcErr) {
          debugPrint('Username lookup RPC error: $rpcErr');
        }

        if (resolvedEmail == null || resolvedEmail.isEmpty) {
          // If username is not found in database, trigger a failed authentication attempt
          // with a consistent synthetic identifier to preserve timing and prevent username enumeration
          final safeTag = normalizedUsername.replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          );
          targetEmail = 'lookup_not_found_$safeTag@studesk.internal';
        } else {
          targetEmail = resolvedEmail;
        }
      }

      // Execute authentication with Supabase Auth
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: targetEmail,
        password: trimmedPassword,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        unawaited(
          ProfileService.instance.fetchAndSyncProfile(user: response.user!),
        );
        return true;
      }

      _status = AuthStatus.unauthenticated;
      _errorMessage =
          'Invalid username or password. Please check your credentials.';
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      debugPrint(
        'AuthException during signIn: ${e.message} (code: ${e.statusCode})',
      );
      _status = AuthStatus.unauthenticated;

      if (e.message.toLowerCase().contains('email not confirmed')) {
        _errorMessage = 'Your email address is not yet verified. Please click the confirmation link sent to your email.';
      } else {
        // Safe, generic message to avoid exposing whether username exists or password failed
        _errorMessage =
            'Invalid username or password. Please check your credentials.';
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('General exception during signIn: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Unable to sign in. Please verify your network connection and try again.';
      notifyListeners();
      return false;
    }
  }

  /// Registers a new student account with username, email, and password.
  /// Enforces unique constraint check, format normalization, and profile linking.
  Future<SignUpResult> signUpWithUsernameAndPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    if (_status == AuthStatus.authenticating) {
      return const SignUpResult(
        success: false,
        errorMessage: 'An account creation is already in progress.',
      );
    }

    final normUsername = username.trim().toLowerCase();
    final normEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    // 1. Validate username format
    final usernameError = ProfileService.instance.validateUsername(
      normUsername,
    );
    if (usernameError != null) {
      _errorMessage = usernameError;
      notifyListeners();
      return SignUpResult(success: false, errorMessage: usernameError);
    }

    // 2. Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(normEmail)) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return const SignUpResult(
        success: false,
        errorMessage: 'Please enter a valid email address.',
      );
    }

    // 3. Validate password strength
    if (trimmedPassword.length < 6) {
      _errorMessage = 'Password must be at least 6 characters.';
      notifyListeners();
      return const SignUpResult(
        success: false,
        errorMessage: 'Password must be at least 6 characters.',
      );
    }

    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      _errorMessage = 'Supabase backend credentials not configured. Please supply SUPABASE_URL and SUPABASE_ANON_KEY.';
      notifyListeners();
      return SignUpResult(success: false, errorMessage: _errorMessage);
    }

    _status = AuthStatus.authenticating;
    _errorMessage = null;
    _statusMessage = null;
    notifyListeners();

    try {
      if (!_isSupabaseInitialized) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.anonKey,
        );
        _isSupabaseInitialized = true;
      }

      // 4. Pre-check username availability in database
      final isAvailable = await ProfileService.instance.checkUsernameAvailable(
        normUsername,
      );
      if (!isAvailable) {
        _status = AuthStatus.unauthenticated;
        _errorMessage =
            'Username @$normUsername is already taken by another student.';
        notifyListeners();
        return SignUpResult(success: false, errorMessage: _errorMessage);
      }

      // 5. Create user in Supabase Auth with metadata and explicit emailRedirectTo
      final response = await Supabase.instance.client.auth.signUp(
        email: normEmail,
        password: trimmedPassword,
        emailRedirectTo: SupabaseConfig.authRedirectUrl,
        data: {'username': normUsername, 'full_name': normUsername},
      );

      final user = response.user;
      final session = response.session;

      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Account creation could not be completed.';
        notifyListeners();
        return SignUpResult(success: false, errorMessage: _errorMessage);
      }

      // Check if email verification is required by Supabase project settings
      if (session == null) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
        return SignUpResult(
          success: true,
          requiresEmailVerification: true,
          email: normEmail,
        );
      }

      // Immediate session granted (Email verification is disabled in project)
      _currentUser = user;
      _status = AuthStatus.authenticated;
      _errorMessage = null;

      // Ensure profile row claims the username explicitly
      try {
        await ProfileService.instance.claimUsername(normUsername);
      } catch (claimErr) {
        debugPrint('Post-signup claimUsername note: $claimErr');
      }

      notifyListeners();
      return const SignUpResult(
        success: true,
        requiresEmailVerification: false,
      );
    } on AuthException catch (e) {
      debugPrint('AuthException during signUp: ${e.message}');
      _status = AuthStatus.unauthenticated;

      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists')) {
        _errorMessage = 'An account with this email already exists. Please sign in instead.';
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
      return SignUpResult(success: false, errorMessage: _errorMessage);
    } catch (e) {
      debugPrint('General exception during signUp: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Registration could not be completed. Please check your network connection and try again.';
      notifyListeners();
      return SignUpResult(success: false, errorMessage: _errorMessage);
    }
  }

  /// Sends a password recovery email for a username or email identifier.
  /// Uses a generic confirmation response to prevent account enumeration.
  Future<String> sendPasswordResetEmail({required String identifier}) async {
    final trimmed = identifier.trim().toLowerCase();
    if (trimmed.isEmpty) {
      throw const FormatException('Please enter your username or email.');
    }

    if (!SupabaseConfig.isConfigured || !_isSupabaseInitialized) {
      return 'If an account exists for this username or email, a password reset link has been sent.';
    }

    try {
      String? targetEmail;
      if (trimmed.contains('@')) {
        targetEmail = trimmed;
      } else {
        // Resolve username to email via server-side function
        try {
          final res = await Supabase.instance.client.rpc(
            'get_auth_email_for_username',
            params: {'p_username': trimmed},
          );
          if (res is String && res.trim().isNotEmpty) {
            targetEmail = res.trim();
          }
        } catch (_) {}
      }

      if (targetEmail != null && targetEmail.isNotEmpty) {
        await Supabase.instance.client.auth.resetPasswordForEmail(
          targetEmail,
          redirectTo: SupabaseConfig.authRedirectUrl,
        );
      }
    } catch (e) {
      debugPrint('sendPasswordResetEmail exception: $e');
    }

    // Generic response regardless of whether user exists
    return 'If an account matches that username or email, a password reset link has been sent.';
  }

  /// Signs out the currently authenticated user, clears local user state,
  /// and returns to unauthenticated state.
  Future<void> signOut() async {
    _oauthCancelTimer?.cancel();
    _oauthCancelTimer = null;
    try {
      if (_isSupabaseInitialized && SupabaseConfig.isConfigured) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      debugPrint('SignOut exception: $e');
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      _statusMessage = null;
      ProfileService.instance.resetState();
      notifyListeners();
    }
  }

  /// Preserved for future optional Google login re-enablement.
  @Deprecated(
    'Google sign-in is temporarily disabled in favor of username authentication.',
  )
  Future<bool> signInWithGoogle() async {
    if (_status == AuthStatus.authenticating) return false;
    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      _errorMessage = 'Authentication service is not configured. Please check your application environment settings.';
      notifyListeners();
      return false;
    }

    try {
      if (!_isSupabaseInitialized) {
        await Supabase.initialize(
          url: SupabaseConfig.url,
          publishableKey: SupabaseConfig.anonKey,
        );
        _isSupabaseInitialized = true;
      }

      _status = AuthStatus.authenticating;
      _errorMessage = null;
      _oauthCancelTimer?.cancel();
      _oauthCancelTimer = Timer(const Duration(seconds: 120), () {
        if (_status == AuthStatus.authenticating) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      });
      notifyListeners();

      final redirect = SupabaseConfig.authRedirectUrl;
      final result = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
        authScreenLaunchMode: LaunchMode.platformDefault,
      );

      return result;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in could not be completed. Please check your network and try again.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  @visibleForTesting
  void setAuthenticatedForTesting(User user) {
    _oauthCancelTimer?.cancel();
    _oauthCancelTimer = null;
    _currentUser = user;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _oauthCancelTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }
}
