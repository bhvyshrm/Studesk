import 'package:flutter/foundation.dart';

/// Configuration for Supabase backend integration and OAuth callbacks.
/// Pass custom values via --dart-define during build/run:
/// `flutter run -d chrome --web-port 5001 --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-publishable-key`
abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kewihlwtrfdepigcwhxf.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_mfY5sxSKrmw_1qd35K8hXQ_R3C3V3CU',
  );

  static const String _configuredWebRedirect = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: '',
  );

  /// Native Android deep link scheme and host
  static const String androidCallbackScheme = 'studesk';
  static const String androidCallbackHost = 'login-callback';
  static const String androidRedirectUrl = 'studesk://login-callback';

  /// Resolves the web redirect URL dynamically to match the current running
  /// origin (e.g. http://localhost:5001 or custom port) unless explicitly overridden.
  static String get webRedirectUrl {
    if (_configuredWebRedirect.trim().isNotEmpty) {
      return _configuredWebRedirect.trim();
    }
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin.startsWith('http')) {
          return origin;
        }
      } catch (_) {
        // Fallback if Uri.base is unavailable
      }
    }
    return 'http://localhost:5001';
  }

  /// Platform-aware OAuth redirect destination.
  /// - Web: Uses running web origin (or explicit override).
  /// - Native Android/Mobile: Uses native deep link (studesk://login-callback).
  static String get authRedirectUrl {
    if (kIsWeb) {
      return webRedirectUrl;
    }
    return androidRedirectUrl;
  }

  static bool get isConfigured =>
      url.trim().isNotEmpty &&
      anonKey.trim().isNotEmpty &&
      url.startsWith('http') &&
      anonKey.length > 20;

  static String get maskedAnonKey {
    if (anonKey.length <= 12) return '••••••••';
    return '${anonKey.substring(0, 8)}...${anonKey.substring(anonKey.length - 4)}';
  }
}
