import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_provider.dart';

class ServiceProviderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getProviderType(int userId) async {
    try {
      await AuthService.ensureValidSession();
      final response =
          await _supabase
              .from('service_providers')
              .select('provider_type')
              .eq('user_id', userId)
              .maybeSingle();
      debugPrint(response.toString());
      if (response != null) {
        return response['provider_type'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching provider type: $e');
      // If it's a JWT error, try one more time with force refresh
      if (e.toString().contains('JWT expired') ||
          (e is PostgrestException && e.code == 'PGRST303')) {
        try {
          await AuthService.ensureValidSession(forceRefresh: true);
          final response =
              await _supabase
                  .from('service_providers')
                  .select('provider_type')
                  .eq('user_id', userId)
                  .maybeSingle();
          if (response != null) {
            return response['provider_type'] as String?;
          }
        } catch (retryError) {
          debugPrint('Retry failed: $retryError');
        }
      }
      return null;
    }
  }

  Future<ServiceProvider?> getProviderProfile(int userId) async {
    try {
      await AuthService.ensureValidSession();
      final response =
          await _supabase
              .from('service_providers')
              .select('*, users(name, phone, city)')
              .eq('user_id', userId)
              .maybeSingle();

      if (response != null) {
        return ServiceProvider.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching provider profile: $e');
      return null;
    }
  }

  /// Fetch a provider profile by provider (service_providers.id)
  Future<ServiceProvider?> getProviderById(int providerId) async {
    try {
      await AuthService.ensureValidSession();
      final response =
          await _supabase
              .from('service_providers')
              .select('*, users(name, phone, city)')
              .eq('id', providerId)
              .maybeSingle();

      if (response != null) {
        return ServiceProvider.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching provider by id: $e');
      return null;
    }
  }

  Future<void> updateProviderProfile({
    required int userId,
    required String businessName,
    required String phone,
    required String city,
    required String email,
  }) async {
    try {
      await AuthService.ensureValidSession();

      // 1. Update public.users table (phone, city)
      await _supabase
          .from('users')
          .update({'phone': phone, 'city': city})
          .eq('user_id', _supabase.auth.currentUser!.id);

      // 2. Update service_providers table (business_name)
      await _supabase
          .from('service_providers')
          .update({'business_name': businessName})
          .eq('user_id', userId);

      // 3. Update Auth email if changed
      final currentEmail = _supabase.auth.currentUser?.email;
      if (currentEmail != email) {
        await _supabase.auth.updateUser(UserAttributes(email: email));
      }
    } catch (e) {
      debugPrint('Error updating provider profile: $e');
      rethrow;
    }
  }
}
