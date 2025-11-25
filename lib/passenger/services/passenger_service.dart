import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/passenger/models/passenger.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerService {
  static Future<Passenger?> getCurrentPassenger() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 Fetching passenger for user: ${user.id}');

      // Query by user_id instead of passenger id
      final response =
          await Supabase.instance.client
              .from('passengers')
              .select('''
          *,
          user:users!passengers_user_id_fkey(*)
        ''')
              .eq('user_id', user.id)
              .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ No passenger profile found for user');
        return null;
      }

      debugPrint('✅ Current passenger data retrieved');
      return Passenger.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase error: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error fetching current passenger: $e');
      throw Exception('Error fetching passenger profile: $e');
    }
  }

  getNearByDrivers(int range, double latitude, double longitude) async {
    // Example: Find drivers within 5km
    final response = await Supabase.instance.client
        .from('drivers')
        .select()
        .filter(
          'location',
          'st_dwithin',
          'POINT($longitude $latitude)::geography, 5000',
        ); // 5000 meters
  }

  static Future<void> updatePassengerLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final passengerId = await AuthService.getPassengerId();

      if (passengerId == null) {
        throw Exception('Passenger profile not found');
      }

      // Update location using PostGIS Point geometry
      await Supabase.instance.client
          .from('passengers')
          .update({
            'location':
                'POINT($longitude $latitude)', // PostGIS format: POINT(lng lat)
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', passengerId);

      debugPrint('✅ Passenger location updated: ($latitude, $longitude)');
    } catch (e) {
      debugPrint('❌ Error updating passenger location: $e');
      // Don't rethrow to avoid crashing the app loop, just log
    }
  }
}
