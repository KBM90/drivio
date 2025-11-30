import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
}
