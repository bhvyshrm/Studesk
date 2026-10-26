import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/data/studesk_repository.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/data/auth_service.dart';

class ProfileService extends ChangeNotifier {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  static final RegExp usernameRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  static const Set<String> reservedUsernames = {
    'admin',
    'administrator',
    'studesk',
    'support',
    'root',
    'system',
    'help',
    'api',
    'null',
    'undefined',
    'moderator',
    'staff',
    'security',
    'guest',
    'user',
    'official',
  };

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get lastError => _lastError;

  void resetState() {
    _isLoading = false;
    _hasLoaded = false;
    _lastError = null;
    notifyListeners();
  }

  /// Synchronous client-side format & reserved-word validation
  String? validateUsername(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Username cannot be blank.';
    }
    final normalized = input.trim().toLowerCase();
    if (normalized.length < 3) {
      return 'Username must be at least 3 characters.';
    }
    if (normalized.length > 20) {
      return 'Username cannot exceed 20 characters.';
    }
    if (!usernameRegex.hasMatch(normalized)) {
      return 'Use lowercase letters, numbers, and underscores only.';
    }
    if (reservedUsernames.contains(normalized)) {
      return 'This username is reserved. Please pick another.';
    }
    return null;
  }

  /// Checks whether a username is available against the real Supabase database.
  Future<bool> checkUsernameAvailable(String username) async {
    final validationError = validateUsername(username);
    if (validationError != null) {
      return false;
    }

    final normalized = username.trim().toLowerCase();

    if (!SupabaseConfig.isConfigured ||
        !AuthService.instance.isSupabaseInitialized) {
      return true;
    }

    try {
      final result = await Supabase.instance.client.rpc(
        'check_username_available',
        params: {'requested_username': normalized},
      );
      if (result is bool) {
        return result;
      }
    } catch (_) {
      // Fallback check against profiles table if RPC is not yet registered
      try {
        final currentUserId =
            Supabase.instance.client.auth.currentSession?.user.id;
        final query = Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('username', normalized);
        final response = await query;
        if (response.isNotEmpty) {
          final first = response.first;
          if (first['id'] == currentUserId) {
            return true;
          }
          return false;
        }
        return true;
      } catch (err) {
        debugPrint('Fallback username availability check failed: $err');
      }
    }

    return true;
  }

  /// Atomically claims and persists the student's username to the database and local cache.
  Future<void> claimUsername(String username) async {
    final validationError = validateUsername(username);
    if (validationError != null) {
      throw FormatException(validationError);
    }

    final normalized = username.trim().toLowerCase();
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final user = AuthService.instance.currentUser;
      final isInitialized =
          SupabaseConfig.isConfigured &&
          AuthService.instance.isSupabaseInitialized;
      final session = isInitialized
          ? Supabase.instance.client.auth.currentSession
          : null;
      final currentUserId =
          user?.id ?? session?.user.id ?? StuDeskRepository.instance.profile.id;

      if (isInitialized && session != null) {
        bool rpcSucceeded = false;
        try {
          final rpcRes = await Supabase.instance.client.rpc(
            'claim_username',
            params: {'new_username': normalized},
          );
          if (rpcRes is Map) {
            if (rpcRes['success'] != true) {
              final rpcErr =
                  rpcRes['error']?.toString() ?? 'Failed to claim username.';
              throw Exception(rpcErr);
            }
            rpcSucceeded = true;
          }
        } catch (rpcErr) {
          debugPrint('claim_username RPC error: $rpcErr');
          // If RPC returned an explicit business failure or error, rethrow immediately
          final errStr = rpcErr.toString();
          if (errStr.contains('already taken') ||
              errStr.contains('reserved') ||
              errStr.contains('characters') ||
              errStr.contains('Unauthenticated') ||
              rpcErr is Exception) {
            rethrow;
          }
        }

        if (!rpcSucceeded) {
          // Direct profile table update fallback for environments where RPC is missing
          try {
            await Supabase.instance.client.from('profiles').upsert({
              'id': currentUserId,
              'username': normalized,
              'onboarding_completed': true,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            });
          } catch (e) {
            final errStr = e.toString().toLowerCase();
            if (errStr.contains('onboarding_completed') ||
                errStr.contains('column') &&
                    errStr.contains('does not exist')) {
              await Supabase.instance.client.from('profiles').upsert({
                'id': currentUserId,
                'username': normalized,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              });
            } else {
              rethrow;
            }
          }
        }
      }

      // Update local repository profile
      final currentProfile = StuDeskRepository.instance.profile;
      final updatedProfile = currentProfile.copyWith(
        username: normalized,
        onboardingCompleted: true,
      );
      await StuDeskRepository.instance.updateProfile(updatedProfile);
      _hasLoaded = true;
      _lastError = null;
    } on PostgrestException catch (e) {
      if (e.code == '23505' ||
          e.message.toLowerCase().contains('unique') ||
          e.message.toLowerCase().contains('duplicate')) {
        _lastError = 'This username was just claimed by another student. Please pick a different one.';
        throw Exception(_lastError);
      }
      _lastError = e.message;
      rethrow;
    } catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads the profile from Supabase for the authenticated user,
  /// creates it if it does not exist yet, and syncs it to local repository.
  Future<UserProfile> fetchAndSyncProfile({required User user}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final fallbackEmail = user.email ?? '';
    final fallbackUsername = (user.userMetadata?['username'] as String?)
        ?.trim()
        .toLowerCase();
    final fallbackName =
        (user.userMetadata?['full_name'] as String?) ??
        (user.userMetadata?['name'] as String?) ??
        (fallbackUsername != null && fallbackUsername.isNotEmpty
            ? fallbackUsername
            : (fallbackEmail.isNotEmpty
                  ? fallbackEmail.split('@').first
                  : 'Student'));
    final fallbackAvatar =
        (user.userMetadata?['avatar_url'] as String?) ??
        (user.userMetadata?['picture'] as String?);

    if (!SupabaseConfig.isConfigured ||
        !AuthService.instance.isSupabaseInitialized) {
      _isLoading = false;
      _hasLoaded = true;
      notifyListeners();
      return StuDeskRepository.instance.profile;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Safe profile creation on first login with zero fake seed data
        // Uses metadata username if present from registration
        final hasUsername =
            fallbackUsername != null && fallbackUsername.isNotEmpty;
        final initialMap = {
          'id': user.id,
          'username': hasUsername ? fallbackUsername : null,
          'full_name': fallbackName,
          'preferred_name': fallbackName.isNotEmpty
              ? fallbackName.split(' ').first
              : '',
          'avatar_url': fallbackAvatar ?? '',
          'institution': '',
          'course': '',
          'academic_year': '',
          'semester': '',
          'bio': '',
          'onboarding_completed': hasUsername,
        };

        try {
          await Supabase.instance.client.from('profiles').upsert(initialMap);
        } catch (err) {
          debugPrint('Error inserting initial profile row: $err');
          // If schema is missing extended columns, fallback to base columns
          try {
            await Supabase.instance.client.from('profiles').upsert({
              'id': user.id,
              'username': hasUsername ? fallbackUsername : null,
              'full_name': fallbackName,
              'avatar_url': fallbackAvatar ?? '',
              'institution': '',
              'course': '',
              'academic_year': '',
              'semester': '',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            });
          } catch (fallbackErr) {
            debugPrint(
              'Error inserting initial profile base row: $fallbackErr',
            );
          }
        }

        final newProfile = UserProfile.fromSupabase(
          initialMap,
          fallbackEmail: fallbackEmail,
          fallbackName: fallbackName,
          fallbackAvatar: fallbackAvatar,
          fallbackUsername: fallbackUsername,
        );
        await StuDeskRepository.instance.updateProfile(newProfile);
        unawaited(
          StuDeskRepository.instance.fetchAndSyncAllDataFromSupabase(
            user: user,
          ),
        );
        _isLoading = false;
        _hasLoaded = true;
        _lastError = null;
        notifyListeners();
        return newProfile;
      }

      final profile = UserProfile.fromSupabase(
        response,
        fallbackEmail: fallbackEmail,
        fallbackName: fallbackName,
        fallbackAvatar: fallbackAvatar,
        fallbackUsername: fallbackUsername,
      );

      // Backfill database username if metadata had it but profile table row missed it
      final rowUsername = (response['username'] as String?)?.trim();
      if ((rowUsername == null || rowUsername.isEmpty) &&
          fallbackUsername != null &&
          fallbackUsername.isNotEmpty) {
        try {
          await Supabase.instance.client
              .from('profiles')
              .update({
                'username': fallbackUsername,
                'onboarding_completed': true,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              })
              .eq('id', user.id);
        } catch (backfillErr) {
          debugPrint('Username backfill note: $backfillErr');
        }
      }

      await StuDeskRepository.instance.updateProfile(profile);
      unawaited(
        StuDeskRepository.instance.fetchAndSyncAllDataFromSupabase(user: user),
      );
      _isLoading = false;
      _hasLoaded = true;
      _lastError = null;
      notifyListeners();
      return profile;
    } catch (e) {
      debugPrint('ProfileService fetchAndSyncProfile error: $e');
      _lastError = 'Unable to connect to your profile. Please check your network connection.';
      _isLoading = false;
      notifyListeners();
      return StuDeskRepository.instance.profile;
    }
  }

  /// Saves edited profile details both to Supabase and local cache.
  Future<void> saveProfile(UserProfile profile) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured &&
          AuthService.instance.isSupabaseInitialized &&
          Supabase.instance.client.auth.currentSession != null) {
        try {
          await Supabase.instance.client
              .from('profiles')
              .upsert(profile.toSupabaseMap());
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('column') && errStr.contains('does not exist')) {
            // Fallback for older profiles table without optional extended columns
            final baseMap = {
              'id': profile.id,
              'username': profile.username.trim().isNotEmpty
                  ? profile.username.trim().toLowerCase()
                  : null,
              'full_name': profile.name,
              'avatar_url': profile.avatarUrl ?? '',
              'institution': profile.college,
              'course': profile.course,
              'academic_year': profile.academicYear,
              'semester': profile.semester,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            };
            await Supabase.instance.client.from('profiles').upsert(baseMap);
          } else {
            rethrow;
          }
        }
      }

      await StuDeskRepository.instance.updateProfile(profile);
      _hasLoaded = true;
    } catch (e) {
      debugPrint('ProfileService saveProfile error: $e');
      _lastError = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
