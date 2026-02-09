// ride_request_services.dart
import 'dart:convert';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Add to pubspec.yaml: uuid: ^4.5.1
import 'package:crypto/crypto.dart'; // Add to pubspec.yaml: crypto: ^3.0.3

class RideRequestServices {
  static Future<Map<String, dynamic>> createRideRequest({
    required LatLng pickup,
    required LatLng destination,
    required int transportTypeId,
    required double price,
    required int paymentMethodId,
    String? instructions, // Add instructions parameter
  }) async {
    try {
      // Get passenger ID from AuthService
      final passengerId = await AuthService.getPassengerId();
      if (passengerId == null) {
        throw Exception('Passenger profile not found. Please log in again.');
      }

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      // Calculate distance and duration
      final distance = await OSRMService().getDistance(pickup, destination);
      final duration = await OSRMService().getDuration(pickup, destination);

      // Validate data
      if (distance <= 0) {
        return {'success': false, 'message': 'Invalid distance calculated'};
      }
      if (duration <= 0) {
        return {'success': false, 'message': 'Invalid duration calculated'};
      }
      if (price <= 0) {
        return {'success': false, 'message': 'Invalid price'};
      }

      // Generate QR code
      final qrCodeValue = generateQrCodeValue();

      // Check if passenger already has an active ride request
      final existingRide =
          await Supabase.instance.client
              .from('ride_requests')
              .select('id, status')
              .eq('passenger_id', passengerId)
              .inFilter('status', ['pending', 'accepted', 'in_progress'])
              .maybeSingle();

      if (existingRide != null) {
        return {
          'success': false,
          'message': 'You already have a ride in progress.',
          'ride_request_id': existingRide['id'],
          'status': existingRide['status'],
        };
      }

      // Prepare data for Supabase with proper PostGIS format
      final Map<String, dynamic> rideRequestData = {
        'passenger_id': passengerId,
        'status': 'pending',
        // Add SRID=4326 for proper PostGIS geometry
        'pickup_location':
            'SRID=4326;POINT(${pickup.longitude} ${pickup.latitude})',
        'dropoff_location':
            'SRID=4326;POINT(${destination.longitude} ${destination.latitude})',
        'distance': distance,
        'price': price,
        'transport_type_id': transportTypeId,
        'payment_method_id': paymentMethodId,
        'duration': duration,
        'qr_code': qrCodeValue,
        'qr_code_scanned': false,
        'instructions': instructions, // Add instructions to data
      };

      // Insert into Supabase
      final response =
          await Supabase.instance.client
              .from('ride_requests')
              .insert(rideRequestData)
              .select('id')
              .single();

      final rideRequestId = response['id'];

      // ✅ Create notification for the user
      try {
        final userId = await AuthService.getInternalUserId();
        if (userId != null) {
          await Supabase.instance.client.from('notifications').insert({
            'user_id': userId,
            'title': 'Ride Requested',
            'body':
                'Your ride request has been created successfully. Waiting for a driver...',
            'data': {'ride_request_id': rideRequestId, 'category': 'system'},
            // 'created_at': DateTime.now().toUtc().toIso8601String(), // Let DB handle default
          });
        }
      } catch (e) {
        debugPrint('⚠️ Failed to create notification: $e');
        // Don't fail the whole request if notification fails
      }

      return {
        'success': true,
        'message': 'Ride request created successfully.',
        'ride_request_id': rideRequestId,
      };
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase error: ${e.message}');
      debugPrint('❌ Error code: ${e.code}');
      debugPrint('❌ Error details: ${e.details}');
      debugPrint('❌ Error hint: ${e.hint}');

      // Handle specific Supabase errors
      if (e.code == '23505') {
        return {
          'success': false,
          'message': 'A ride request with this information already exists.',
        };
      } else if (e.code == '23503') {
        return {
          'success': false,
          'message': 'Invalid transport type or payment method.',
        };
      } else if (e.code == '42501') {
        // Permission denied
        return {
          'success': false,
          'message': 'Permission denied. Check RLS policies.',
        };
      } else if (e.code == '23514') {
        // Check constraint violation
        return {
          'success': false,
          'message': 'Data validation failed: ${e.message}',
        };
      }

      return {'success': false, 'message': 'Database error: ${e.message}'};
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating ride request: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  // Method to fetch ride request with all related data
  static Future<RideRequest?> getCurrentRideRequest() async {
    try {
      final passengerId = await AuthService.getPassengerId();

      if (passengerId == null) {
        debugPrint('❌ Passenger ID is null, cannot fetch ride request');
        return null;
      }

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      final response =
          await Supabase.instance.client
              .from('ride_requests')
              .select('''
          *,
          passenger:passengers!ride_requests_passenger_id_fkey(*),
          driver:drivers!ride_requests_driver_id_fkey(*),
          transport_type:transport_types!ride_requests_transport_type_id_fkey(*)
        ''')
              .eq('passenger_id', passengerId)
              .inFilter('status', ['pending', 'accepted', 'in_progress'])
              .order('created_at', ascending: false)
              .maybeSingle();

      if (response == null) {
        debugPrint('No active ride request found');
        return null;
      }

      // Parse location data
      final pickupGeoJson = response['pickup_location'] as Map<String, dynamic>;
      final dropoffGeoJson =
          response['dropoff_location'] as Map<String, dynamic>;

      // Convert GeoJSON to Location objects
      final pickupLocation = Location(
        latitude: (pickupGeoJson['coordinates'] as List)[1],
        longitude: (pickupGeoJson['coordinates'] as List)[0],
      );

      final dropoffLocation = Location(
        latitude: (dropoffGeoJson['coordinates'] as List)[1],
        longitude: (dropoffGeoJson['coordinates'] as List)[0],
      );

      // Build the proper JSON structure for RideRequest.fromJson
      final rideRequestData = {
        ...response,
        'pickup_location': pickupLocation.toJson(),
        'destination_location': dropoffLocation.toJson(),
        'distance_km': response['distance'],
        'estimated_time_min': response['duration'],
      };

      return RideRequest.fromJson(rideRequestData);
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching current ride request: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<bool> cancelRideRequest(
    String reason,
    int rideRequestId,
  ) async {
    try {
      final passengerId = await AuthService.getPassengerId();
      final userId = await AuthService.getInternalUserId();

      if (passengerId == null) {
        throw Exception('Passenger profile not found. Please log in again.');
      }

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      // Load the ride from DB
      final currentRide =
          await Supabase.instance.client
              .from('ride_requests')
              .select('id, passenger_id, status')
              .eq('id', rideRequestId)
              .maybeSingle();

      if (currentRide == null) {
        debugPrint('❌ Ride request not found');
        return false;
      }

      if (currentRide['passenger_id'] != passengerId) {
        debugPrint('❌ Ride does not belong to this passenger');
        return false;
      }

      // Only pending rides can be cancelled
      if (currentRide['status'] != 'pending') {
        debugPrint(
          '❌ Cannot cancel ride with status: ${currentRide['status']}',
        );
        return false;
      }

      // 🔥 INSERT INTO cancelled_ride_requests FIRST
      await Supabase.instance.client.from('cancelled_ride_requests').insert({
        'ride_request_id': rideRequestId,
        'user_id': userId,
        'user_type': 'passenger',
        'reason': reason,
      });

      // 🔥 THEN delete the ride
      await Supabase.instance.client
          .from('ride_requests')
          .delete()
          .eq('id', rideRequestId);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error cancelling ride request: $e');
      return false;
    }
  }

  /// Generate a secure QR code value
  static String generateQrCodeValue() {
    // Create a unique, secure string
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomUuid = const Uuid().v4();

    // Combine and hash for security
    final input = '$timestamp-$randomUuid';
    final bytes = utf8.encode(input);
    final hash = sha256.convert(bytes);

    return hash.toString();
  }
}
