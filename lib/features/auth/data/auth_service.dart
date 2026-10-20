import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../profile/data/profile_service.dart';

enum AuthStatus {
  uninitialized,
  unconfigured,
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
  bool _isSupabaseInitialized = false;
  StreamSubscription<AuthState>? _authSubscription;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isDemoMode => _isDemoMode || _status == AuthStatus.offlineDemoMode;
  bool get isBackendConfigured => SupabaseConfig.isConfigured;
  bool get isSupabaseInitialized => _isSupabaseInitialized;

  Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      _isDemoMode = false;
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
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          _handleAuthStateChange(data.event, data.session);
        },
        onError: (error) {
          debugPrint('Supabase Auth error listener: $error');
          _errorMessage = error.toString();
          _status = AuthStatus.error;
          notifyListeners();
        },
      );

      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        _currentUser = session.user;
        _status = AuthStatus.authenticated;
        _isDemoMode = false;
        unawaited(ProfileService.instance.fetchAndSyncProfile(user: session.user));
      } else {
        _status = AuthStatus.unauthenticated;
        _isDemoMode = false;
      }
    } catch (e) {
      debugPrint('Supabase initialization exception (fallback to demo mode): $e');
      _errorMessage = e.toString();
      _status = AuthStatus.offlineDemoMode;
      _isDemoMode = true;
    }
    notifyListeners();
  }

  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    debugPrint('StuDesk AuthChangeEvent: $event (hasSession: ${session != null})');

    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (session != null) {
          _currentUser = session.user;
          _status = AuthStatus.authenticated;
          _isDemoMode = false;
          _errorMessage = null;
          notifyListeners();
          unawaited(ProfileService.instance.fetchAndSyncProfile(user: session.user));
        }
        break;

      case AuthChangeEvent.signedOut:
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _isDemoMode = false;
        _errorMessage = null;
        notifyListeners();
        break;

      default:
        break;
    }
  }

  Future<bool> signInWithGoogle() async {
    if (!SupabaseConfig.isConfigured) {
      _status = AuthStatus.unconfigured;
      _errorMessage =
          'Supabase backend credentials not configured. Please supply SUPABASE_URL and SUPABASE_ANON_KEY.';
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

      final redirect = kIsWeb ? SupabaseConfig.webRedirectUrl : 'studesk://login-callback';
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
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  void enterDemoMode() {
    _currentUser = null;
    _status = AuthStatus.offlineDemoMode;
    _isDemoMode = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      if (_isSupabaseInitialized && SupabaseConfig.isConfigured) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      debugPrint('SignOut exception: $e');
    } finally {
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      _isDemoMode = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
