import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is logged in
  static bool get isLoggedIn => _supabase.auth.currentUser != null;

  /// Get current user ID
  static String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Get internal user ID synchronously from cache (must be called after getUserData)
  static int? _cachedInternalUserId;
  static int? _cachedPassengerId;
  static int? _cachedDriverId;

  /// Get user role from metadata, SharedPreferences, or Database
  static Future<String?> getUserRole() async {
    // 1. Try Supabase user metadata
    final user = _supabase.auth.currentUser;
    if (user != null && user.userMetadata != null) {
      final role = user.userMetadata?['role'] as String?;
      if (role != null) {
        await SharedPreferencesHelper.setString('role', role);
        return role;
      }
    }

    // 2. Try SharedPreferences
    String? role = await SharedPreferencesHelper().getValue<String>('role');
    if (role != null) return role;

    // 3. Try Database (public.users)
    role = await _getRoleFromDb();
    if (role != null) {
      await SharedPreferencesHelper.setString('role', role);
      return role;
    }

    return null;
  }

  static Future<String?> _getRoleFromDb() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data =
          await _supabase
              .from('users')
              .select('role')
              .eq('user_id', userId)
              .maybeSingle();

      return data?['role'] as String?;
    } catch (e) {
      debugPrint('❌ Error fetching role from DB: $e');
      return null;
    }
  }

  /// Check if the current user is banned
  static Future<bool> isUserBanned() async {
    try {
      await ensureValidSession(); // Ensure valid session before DB call

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      try {
        final data =
            await _supabase
                .from('users')
                .select('banned')
                .eq('user_id', userId)
                .maybeSingle();

        if (data == null) return false;

        final isBanned = data['banned'] as bool? ?? false;

        return isBanned;
      } on PostgrestException catch (e) {
        // Handle JWT expiration
        if (e.code == 'PGRST303') {
          debugPrint(
            '⚠️ JWT Expired during banned check. Forcing refresh and retrying...',
          );

          await ensureValidSession(forceRefresh: true);

          // Retry
          final data =
              await _supabase
                  .from('users')
                  .select('banned')
                  .eq('user_id', userId)
                  .maybeSingle();

          if (data == null) return false;
          return data['banned'] as bool? ?? false;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ Error checking banned status: $e');
      return false; // Default to not banned on error
    }
  }

  static Future<AuthResponse> signUpWithEmail({
    required String name,
    required String email,
    required String city,
    required String countryCode,
    required String phone,
    required String password,
    required String role, // 'driver' or 'passenger'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role,
          'name': name,
          'city': city,
          'country_code': countryCode,
          'phone': phone,
          ...?additionalData,
        },
      );

      final user = response.user;

      if (user == null) {
        throw Exception("User creation failed — no user returned.");
      }

      // ✅ Store role in SharedPreferences
      await SharedPreferencesHelper.setString('role', role);

      // ✅ The trigger automatically creates:
      //    1. Record in public.users
      //    2. Record in drivers or passengers table
      // No manual insertion needed!

      debugPrint('✅ Sign up successful for ${user.email} as $role');

      return response;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Get and store role
      if (response.user != null) {
        final role = response.user!.userMetadata?['role'] as String?;
        if (role != null) {
          await SharedPreferencesHelper.setString('role', role);
        }
      }

      debugPrint('✅ Sign in successful: ${response.user?.email}');
      return response;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  /// Ensure the current session is valid and refresh if necessary
  static Future<void> ensureValidSession({bool forceRefresh = false}) async {
    try {
      final session = _supabase.auth.currentSession;

      if (session == null) {
        debugPrint('⚠️ No active session found');
        return;
      }

      /* debugPrint(
        '🔍 Session check: isExpired=${session.isExpired}, forceRefresh=$forceRefresh',
      );*/

      // Refresh if expired OR forced
      if (session.isExpired || forceRefresh) {
        debugPrint(
          '🔄 Refreshing session (Expired: ${session.isExpired}, Forced: $forceRefresh)...',
        );
        try {
          final response = await _supabase.auth.refreshSession();

          if (response.session != null) {
            debugPrint('✅ Session refreshed successfully');
          } else {
            debugPrint(
              '❌ Session refresh returned null - user needs to re-login',
            );
            await signOut(); // Force logout
            throw AuthException('Session refresh failed - please log in again');
          }
        } catch (refreshError) {
          debugPrint('❌ Failed to refresh session: $refreshError');
          debugPrint('⚠️ User needs to log out and log back in');
          await signOut(); // Force logout
          throw AuthException(
            'Session expired and refresh failed - please log in again',
          );
        }
      } else {
        ///debugPrint('✅ Session is valid');
      }
    } catch (e) {
      debugPrint('❌ Error in ensureValidSession: $e');
      if (e is AuthException) {
        rethrow;
      }
    }
  }

  /// Get internal user ID from users table
  static Future<int?> getInternalUserId() async {
    if (_cachedInternalUserId != null) return _cachedInternalUserId;

    try {
      await ensureValidSession(); // Ensure valid token before DB call

      final authUserId = _supabase.auth.currentUser?.id;
      if (authUserId == null) return null;

      try {
        final response =
            await _supabase
                .from('users')
                .select('id')
                .eq('user_id', authUserId)
                .single();

        _cachedInternalUserId = response['id'] as int?;
        return _cachedInternalUserId;
      } on PostgrestException catch (e) {
        // 🚨 Handle JWT Expiration specifically
        if (e.code == 'PGRST303') {
          debugPrint(
            '⚠️ JWT Expired during DB call. Forcing refresh and retrying...',
          );

          // Force refresh
          await ensureValidSession(forceRefresh: true);

          // Retry DB call
          final response =
              await _supabase
                  .from('users')
                  .select('id')
                  .eq('user_id', authUserId)
                  .single();

          _cachedInternalUserId = response['id'] as int?;
          return _cachedInternalUserId;
        }
        rethrow; // Rethrow other PostgrestExceptions
      }
    } catch (e) {
      debugPrint('❌ Error getting internal user ID: $e');

      // If we still fail after retry, it might be time to logout
      if (e.toString().contains('JWT expired') ||
          (e is PostgrestException && e.code == 'PGRST303')) {
        debugPrint('❌ Unrecoverable JWT error. Signing out.');
        await signOut();
      }

      return null;
    }
  }

  /// Get passenger ID for current user
  static Future<int?> getPassengerId() async {
    if (_cachedPassengerId != null) return _cachedPassengerId;

    try {
      final internalUserId = await getInternalUserId();
      if (internalUserId == null) return null;

      final response =
          await _supabase
              .from('passengers')
              .select('id')
              .eq('user_id', internalUserId)
              .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ No passenger profile found');
        return null;
      }

      _cachedPassengerId = response['id'] as int?;
      return _cachedPassengerId;
    } catch (e) {
      debugPrint('❌ Error getting passenger ID: $e');
      return null;
    }
  }

  /// Get driver ID for current user
  static Future<int?> getDriverId() async {
    if (_cachedDriverId != null) return _cachedDriverId;

    try {
      final internalUserId = await getInternalUserId();
      if (internalUserId == null) return null;

      final response =
          await _supabase
              .from('drivers')
              .select('id')
              .eq('user_id', internalUserId)
              .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ No driver profile found');
        return null;
      }

      _cachedDriverId = response['id'] as int?;
      return _cachedDriverId;
    } catch (e) {
      debugPrint('❌ Error getting driver ID: $e');
      return null;
    }
  }

  /// Initialize and cache all user-related IDs
  static Future<void> initializeUserData() async {
    try {
      await getInternalUserId();
      final role = await getUserRole();

      // Cache the appropriate ID based on role
      if (role == 'passenger') {
        await getPassengerId();
      } else if (role == 'driver') {
        await getDriverId();
      }

      debugPrint('✅ User data initialized');
    } catch (e) {
      debugPrint('❌ Error initializing user data: $e');
    }
  }

  /// Clear cache on logout
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      await SharedPreferencesHelper.remove('role');

      // Clear all cached IDs
      _cachedInternalUserId = null;
      _cachedPassengerId = null;
      _cachedDriverId = null;

      debugPrint('✅ Signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  /// Delete account
  static Future<void> deleteAccount() async {
    try {
      await _supabase.rpc('delete_own_account');
      await signOut(); // Ensure local session is cleared
      debugPrint('✅ Account deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }
}
