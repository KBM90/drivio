import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripHistoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get trip history for the current driver
  Future<List<RideRequest>> getTripHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        debugPrint('❌ No driver ID found');
        return [];
      }

      final response = await _supabase
          .from('ride_requests')
          .select('''
            *,
            passenger:passengers!inner(
              id,
              user_id,
              user:users!inner(
                id,
                name,
                email,
                phone,
                role,
                profile_image_path
              )
            ),
            transport_type:transport_types!inner(
              id,
              name
            ),
            payment_method:payment_methods!inner(
              id,
              name
            )
          ''')
          .eq('driver_id', driverId)
          .inFilter('status', ['completed', 'cancelled_by_driver'])
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final trips =
          (response as List).map((json) {
            try {
              return RideRequest.fromJson(json);
            } catch (e, stackTrace) {
              debugPrint('❌ Error parsing ride request: $e');
              debugPrint('📄 JSON data: $json');
              debugPrint('📚 Stack trace: $stackTrace');
              rethrow;
            }
          }).toList();

      debugPrint('✅ Loaded ${trips.length} trips');
      return trips;
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading trip history: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get trip count for the current driver
  Future<int> getTripCount() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) return 0;

      final count = await _supabase
          .from('ride_requests')
          .count()
          .eq('driver_id', driverId)
          .inFilter('status', ['completed', 'cancelled_by_driver']);

      return count;
    } catch (e) {
      debugPrint('❌ Error getting trip count: $e');
      return 0;
    }
  }
}
