import 'dart:async';
import 'dart:io';
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

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      // Get internal user ID
      final userResponse =
          await supabase
              .from('users')
              .select('id')
              .eq('user_id', userId)
              .single();

      final internalUserId = userResponse['id'] as int;

      // Get driver data with user information
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
          updated_at,
          user:users!inner(
            id,
            name,
            email,
            phone,
            country_code,
            country,
            language,
            sexe,
            is_verified,
            city,
            role,
            profile_image_path,
            banned,
            email_verified_at,
            created_at,
            updated_at,
            user_id
          )
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

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

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

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

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

  /// Update driver-specific information (range, preferences)
  static Future<void> updateDriverInfo({
    double? range,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver profile not found');
      }

      await AuthService.ensureValidSession();

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (range != null) {
        updateData['range'] = range;
      }

      if (preferences != null) {
        updateData['preferences'] = preferences;
      }

      await Supabase.instance.client
          .from('drivers')
          .update(updateData)
          .eq('id', driverId);

      debugPrint('✅ Driver info updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating driver info: $e');
      rethrow;
    }
  }

  /// Update user information (name, phone, gender, profile image)
  static Future<void> updateUserInfo({
    String? name,
    String? phone,
    String? gender,
    String? profileImagePath,
  }) async {
    try {
      final internalUserId = await AuthService.getInternalUserId();
      if (internalUserId == null) {
        throw Exception('User not found');
      }

      await AuthService.ensureValidSession();

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) {
        updateData['name'] = name;
      }

      if (phone != null) {
        updateData['phone'] = phone;
      }

      if (gender != null) {
        updateData['sexe'] =
            gender.toLowerCase(); // Convert to lowercase for database
      }

      if (profileImagePath != null) {
        updateData['profile_image_path'] = profileImagePath;
      }

      await Supabase.instance.client
          .from('users')
          .update(updateData)
          .eq('id', internalUserId);

      debugPrint('✅ User info updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user info: $e');
      rethrow;
    }
  }

  /// Upload profile image to storage
  static Future<String> uploadProfileImage(String filePath) async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) throw Exception('User ID not found');

      final fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profiles/$fileName';

      await Supabase.instance.client.storage
          .from('service_images')
          .upload(path, File(filePath));

      final publicUrl = Supabase.instance.client.storage
          .from('service_images')
          .getPublicUrl(path);

      debugPrint('✅ Profile image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading profile image: $e');
      rethrow;
    }
  }
}
