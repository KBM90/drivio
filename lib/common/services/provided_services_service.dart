import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/provided_service.dart';
import '../models/service_provider.dart';

class ProvidedServicesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all services, optionally filtered by category
  Future<List<ProvidedService>> getServices({String? category}) async {
    try {
      var query = _supabase
          .from('provided_services')
          .select(
            '*, service_images(image_url), service_providers(*, users(phone))',
          );

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);

      if (response == null) return [];

      return (response as List)
          .map((e) => ProvidedService.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching services: $e');
      return [];
    }
  }

  /// Fetch services for a specific provider
  Future<List<ProvidedService>> getProviderServices(int providerId) async {
    try {
      final response = await _supabase
          .from('provided_services')
          .select(
            '*, service_images(image_url), service_providers(*, users(phone))',
          )
          .eq('provider_id', providerId)
          .order('created_at', ascending: false);

      if (response == null) return [];

      return (response as List)
          .map((e) => ProvidedService.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching provider services: $e');
      return [];
    }
  }

  /// Fetch all providers, optionally filtered by type
  Future<List<ServiceProvider>> getProviders({String? type}) async {
    try {
      var query = _supabase.from('service_providers').select('*, users(phone)');

      if (type != null && type.isNotEmpty) {
        query = query.eq('provider_type', type);
      }

      final response = await query.order('rating', ascending: false);

      if (response == null) return [];

      return (response as List)
          .map((e) => ServiceProvider.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching providers: $e');
      return [];
    }
  }
}
