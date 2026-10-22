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

/// Dedicated Google Authentication Service using Supabase OAuth.
/// Enforces Google sign-in as the sole supported authentication method.
class AuthService extends ChangeNotifier with WidgetsBindingObserver {
  AuthService._();
  static final AuthService instance = AuthService._();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;
  User? _currentUser;
  bool _isSupabaseInitialized = false;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _cancelTimer;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _currentUser != null;
  bool get isBackendConfigured => SupabaseConfig.isConfigured;
  bool get isSupabaseInitialized => _isSupabaseInitialized;

  void clearError() {
    _errorMessage = null;
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
              _errorMessage =
                  'Authentication connection interrupted. Please try again.';
              _status = AuthStatus.error;
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
      _errorMessage = 'Unable to connect to Supabase: $e';
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_status == AuthStatus.authenticating) {
        _cancelTimer?.cancel();
        _cancelTimer = Timer(const Duration(milliseconds: 1800), () {
          if (_status == AuthStatus.authenticating && _currentUser == null) {
            _status = AuthStatus.unauthenticated;
            _errorMessage = 'Sign-in was cancelled or closed.';
            notifyListeners();
          }
        });
      }
    }
  }

  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    debugPrint(
      'StuDesk AuthChangeEvent: $event (hasSession: ${session != null})',
    );
    _cancelTimer?.cancel();

    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (session != null) {
          _currentUser = session.user;
          _status = AuthStatus.authenticated;
          _errorMessage = null;
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
        ProfileService.instance.resetState();
        notifyListeners();
        break;

      default:
        break;
    }
  }

  Future<bool> signInWithGoogle() async {
    // Prevent duplicate in-flight login requests
    if (_status == AuthStatus.authenticating) {
      return false;
    }

    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      _errorMessage = 'Supabase backend credentials not configured. Please supply SUPABASE_URL and SUPABASE_ANON_KEY.';
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

  Future<void> signOut() async {
    _cancelTimer?.cancel();
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
      ProfileService.instance.resetState();
      notifyListeners();
    }
  }

  @visibleForTesting
  void setAuthenticatedForTesting(User user) {
    _cancelTimer?.cancel();
    _currentUser = user;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }
}
