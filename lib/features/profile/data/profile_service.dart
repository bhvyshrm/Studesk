import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/data/auth_service.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  bool _isLoading = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Loads the profile from Supabase for the authenticated user,
  /// creates it if it does not exist yet, and syncs it to local repository.
  Future<UserProfile> fetchAndSyncProfile({required User user}) async {
    _isLoading = true;
    _lastError = null;

    final fallbackEmail = user.email ?? '';
    final fallbackName = (user.userMetadata?['full_name'] as String?) ??
        (user.userMetadata?['name'] as String?) ??
        (fallbackEmail.isNotEmpty ? fallbackEmail.split('@').first : 'StuDesk Student');
    final fallbackAvatar = (user.userMetadata?['avatar_url'] as String?) ??
        (user.userMetadata?['picture'] as String?);

    if (!SupabaseConfig.isConfigured || !AuthService.instance.isSupabaseInitialized) {
      _isLoading = false;
      return StuDeskRepository.instance.profile;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Safe profile creation on first login
        final initialMap = {
          'id': user.id,
          'full_name': fallbackName,
          'avatar_url': fallbackAvatar ?? '',
          'institution': 'Dept of Computer Science',
          'course': 'B.Tech Computer Science',
          'academic_year': 'Year 2',
          'semester': 'Semester 4',
        };

        await Supabase.instance.client.from('profiles').upsert(initialMap);

        final newProfile = UserProfile.fromSupabase(
          initialMap,
          fallbackEmail: fallbackEmail,
          fallbackName: fallbackName,
          fallbackAvatar: fallbackAvatar,
        );
        await StuDeskRepository.instance.updateProfile(newProfile);
        _isLoading = false;
        return newProfile;
      }

      final profile = UserProfile.fromSupabase(
        response,
        fallbackEmail: fallbackEmail,
        fallbackName: fallbackName,
        fallbackAvatar: fallbackAvatar,
      );

      await StuDeskRepository.instance.updateProfile(profile);
      _isLoading = false;
      return profile;
    } catch (e) {
      debugPrint('ProfileService fetchAndSyncProfile error: $e');
      _lastError = e.toString();
      _isLoading = false;
      // Fallback to locally cached profile
      return StuDeskRepository.instance.profile;
    }
  }

  /// Saves edited profile details both to Supabase and local cache.
  Future<void> saveProfile(UserProfile profile) async {
    _isLoading = true;
    _lastError = null;

    try {
      if (SupabaseConfig.isConfigured &&
          AuthService.instance.isSupabaseInitialized &&
          Supabase.instance.client.auth.currentSession != null) {
        await Supabase.instance.client
            .from('profiles')
            .upsert(profile.toSupabaseMap());
      }

      await StuDeskRepository.instance.updateProfile(profile);
    } catch (e) {
      debugPrint('ProfileService saveProfile error: $e');
      _lastError = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
}
