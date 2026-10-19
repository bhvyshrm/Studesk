import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

enum AuthStatus {
  uninitialized,
  unauthenticated,
  authenticating,
  authenticated,
  offlineDemoMode,
  error,
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;
  User? _currentUser;
  bool _isDemoMode = false;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isDemoMode => _isDemoMode || _status == AuthStatus.offlineDemoMode;
  bool get isBackendConfigured => SupabaseConfig.isConfigured;

  Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.offlineDemoMode;
      _isDemoMode = true;
      notifyListeners();
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _currentUser = session.user;
        _status = AuthStatus.authenticated;
        _isDemoMode = false;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Supabase initialization fallback: $e');
      _status = AuthStatus.offlineDemoMode;
      _isDemoMode = true;
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    if (!SupabaseConfig.isConfigured) {
      _errorMessage =
          'Supabase backend credentials not configured. Running in Local Demo Mode.';
      _status = AuthStatus.offlineDemoMode;
      _isDemoMode = true;
      notifyListeners();
      return false;
    }

    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final result = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'studesk://login-callback',
      );

      if (result) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          _currentUser = session.user;
          _status = AuthStatus.authenticated;
          _isDemoMode = false;
          notifyListeners();
          return true;
        }
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  void enterDemoMode() {
    _status = AuthStatus.offlineDemoMode;
    _isDemoMode = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('SignOut exception: $e');
      }
    }
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _isDemoMode = false;
    notifyListeners();
  }
}
