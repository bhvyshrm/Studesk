/// Configuration for Supabase backend integration.
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

  static const String webRedirectUrl = String.fromEnvironment(
    'SUPABASE_AUTH_REDIRECT_URL',
    defaultValue: 'http://localhost:5001',
  );

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
