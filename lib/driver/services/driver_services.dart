import 'dart:async';
import 'package:drivio_app/common/helpers/custom_exceptions.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverService {
  static Future<Driver> getDriver() async {
    try {
      final supabase = Supabase.instance.client;

      // Get authenticated user
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw UnauthorizedException(
          'User not authenticated. Please login again.',
        );
      }

      // Get internal user ID
      final userResponse =
          await supabase
              .from('users')
              .select('id')
              .eq('user_id', userId)
              .single();

      final internalUserId = userResponse['id'] as int;

      // Get driver data
      final driverResponse =
          await supabase
              .from('drivers')
              .select('''
          id,
          user_id,
          location,
          dropoff_location,
          preferences,
          driving_distance,
          status,
          acceptnewrequest,
          range,
          created_at,
          updated_at
        ''')
              .eq('user_id', internalUserId)
              .single();

      // Add parsed coordinates to response
      final driverData = Map<String, dynamic>.from(driverResponse);

      // Parse location from GeoJSON (Supabase returns PostGIS as GeoJSON)
      final coords = GeolocatorHelper.parseGeoJSON(driverResponse['location']);
      if (coords != null) {
        driverData['latitude'] = coords['latitude'];
        driverData['longitude'] = coords['longitude'];
      } else {
        // Location is NULL - driver hasn't set location yet
        driverData['latitude'] = null;
        driverData['longitude'] = null;
      }

      return Driver.fromJson(driverData);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException('Driver not found.');
      }
      throw ServerErrorException('Database error: ${e.message}');
    } on AuthException catch (e) {
      throw UnauthorizedException('Authentication error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error fetching driver: $e');
      throw Exception('Failed to fetch driver: $e');
    }
  }

  static Future<void> updateDriverLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final driverId = await AuthService.getDriverId();

      if (driverId == null) {
        throw Exception('Driver profile not found');
      }

      // Update location using PostGIS Point geometry
      await Supabase.instance.client
          .from('drivers')
          .update({
            'location':
                'POINT($longitude $latitude)', // PostGIS format: POINT(lng lat)
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      debugPrint('✅ Location updated: ($latitude, $longitude)');
    } catch (e) {
      debugPrint('❌ Error updating location in supabase: $e');
      rethrow;
    }
  }

  static Future<bool> updateDriverDropOffLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver profile not found');
      }

      await Supabase.instance.client
          .from('drivers')
          .update({
            'dropoff_location': 'POINT($longitude $latitude)',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      debugPrint('✅ Drop-off location updated: ($latitude, $longitude)');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating driver drop-off location: $e');
      throw Exception('Error updating driver location: $e');
    }
  }
}
