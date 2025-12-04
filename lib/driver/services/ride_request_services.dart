import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../common/models/ride_request.dart';

class RideRequestService {
  /// Fetch ride requests within the driver's configured range (or 10km default)
  static Future<List<RideRequest>> getNearByRideRequests(
    LatLng driverLocation,
  ) async {
    try {
      // Get the driver's ID
      final driverId = await AuthService.getDriverId();

      // Create a PostGIS POINT geometry string
      // Format: SRID=4326;POINT(longitude latitude) - note the order!
      final driverLocationGeometry =
          'SRID=4326;POINT(${driverLocation.longitude} ${driverLocation.latitude})';

      debugPrint(
        '🔍 Fetching rides near: $driverLocationGeometry for driver: $driverId',
      );

      // Call RPC to get complete ride data with joins
      // This function uses SECURITY DEFINER to bypass RLS policies
      final List<dynamic> rpcResponse = await Supabase.instance.client.rpc(
        'get_nearby_pending_rides',
        params: {
          'driver_location': driverLocationGeometry,
          'p_driver_id':
              driverId, // Pass driver_id to use their range preference
        },
      );

      if (rpcResponse.isEmpty) {
        debugPrint('ℹ️ No nearby ride requests found');
        return [];
      }

      debugPrint('✅ Fetched ${rpcResponse.length} rides with complete data');

      // Convert to RideRequest objects directly from RPC response
      return (rpcResponse).map((json) {
        // Create a mutable copy of the JSON
        final Map<String, dynamic> rideData = Map<String, dynamic>.from(
          json as Map,
        );

        // Map 'distance' from DB to 'distance_km' expected by model
        if (rideData.containsKey('distance')) {
          rideData['distance_km'] = rideData['distance'];
        }

        return RideRequest.fromJson(rideData);
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching ride requests: $e');
      return [];
    }
  }

  ///Fetch the choosen ride request
  static Future<RideRequest> getRideRequest(int id) async {
    try {
      final response =
          await Supabase.instance.client
              .from('ride_requests')
              .select(
                '*, passenger:passengers(*, user:users(*)), driver:drivers(*), transport_type:transport_types(*)',
              )
              .eq('id', id)
              .single();

      debugPrint("🔍 Raw Ride Request Response: $response");

      return RideRequest.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching ride request: $e');
      throw Exception("Error fetching ride request: $e");
    }
  }

  static Future<String?> acceptRideRequest(
    int rideRequestId,
    double latitude,
    double longitude,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // Get current driver ID
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      // Create PostGIS POINT geometry string
      final driverLocation = 'SRID=4326;POINT($longitude $latitude)';

      // Call the RPC function to accept the ride
      // This function has SECURITY DEFINER and can bypass RLS policies
      final response = await supabase.rpc(
        'accept_ride_by_driver',
        params: {
          'p_ride_request_id': rideRequestId,
          'p_driver_id': driverId,
          'p_driver_location': driverLocation,
        },
      );

      // Save current ride ID to SharedPreferences
      await SharedPreferencesHelper.setInt("currentRideId", rideRequestId);

      debugPrint('✅ Ride request $rideRequestId accepted by driver $driverId');
      return response['message'] as String?;
    } catch (e) {
      debugPrint('❌ Error accepting ride request: $e');
      throw Exception('Error accepting ride request: $e');
    }
  }

  static Future<String?> cancelTrip(String reason) async {
    try {
      final supabase = Supabase.instance.client;

      // Get current driver ID
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      // Get current ride request ID from SharedPreferences
      final rideRequestId = await SharedPreferencesHelper().getInt(
        "currentRideId",
      );
      if (rideRequestId == null) {
        throw Exception('No active ride found');
      }

      // Call the RPC function to cancel the trip
      // This function has SECURITY DEFINER and can bypass RLS policies
      final response = await supabase.rpc(
        'cancel_ride_by_driver',
        params: {
          'p_ride_request_id': rideRequestId,
          'p_driver_id': driverId,
          'p_reason': reason,
        },
      );

      // Clear current ride ID from SharedPreferences
      await SharedPreferencesHelper.remove("currentRideId");

      debugPrint('✅ Trip $rideRequestId cancelled by driver');
      return response['message'] as String?;
    } catch (e) {
      debugPrint('❌ Error cancelling trip: $e');
      throw Exception('Error cancelling trip: $e');
    }
  }

  static Future<String> stopNewRequsts() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      await Supabase.instance.client
          .from('drivers')
          .update({
            'acceptnewrequest': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      return 'You have stopped receiving new requests';
    } catch (e) {
      throw Exception('Error updating driver availability: $e');
    }
  }

  static Future<String> acceptNewRequests() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      await Supabase.instance.client
          .from('drivers')
          .update({
            'acceptnewrequest': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      return 'You are now receiving new requests';
    } catch (e) {
      throw Exception('Error updating driver availability: $e');
    }
  }

  /// Mark driver as arrived at pickup location
  static Future<void> driverArrived(int rideRequestId) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) throw Exception('Driver not found');

      debugPrint('📍 Driver arrived for ride $rideRequestId');

      await Supabase.instance.client
          .from('ride_requests')
          .update({
            'status': 'arrived',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rideRequestId)
          .eq('driver_id', driverId);

      debugPrint('✅ Ride status updated to arrived');
    } catch (e) {
      debugPrint('❌ Error updating arrival status: $e');
      throw Exception('Failed to update arrival status: $e');
    }
  }

  /// Start trip after verifying QR code
  static Future<void> startTrip(int rideRequestId, String qrCode) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) throw Exception('Driver not found');

      debugPrint('🚀 Starting trip $rideRequestId with QR: $qrCode');

      // Verify QR code and start trip via RPC or direct update
      // For now, we'll verify locally and update

      // 1. Fetch the ride request to check QR code
      final ride =
          await Supabase.instance.client
              .from('ride_requests')
              .select('qr_code, status')
              .eq('id', rideRequestId)
              .single();

      if (ride['qr_code'] != qrCode) {
        throw Exception('Invalid QR Code');
      }

      // 2. Update status to in_progress
      await Supabase.instance.client
          .from('ride_requests')
          .update({
            'status': 'in_progress',
            'qr_code_scanned': true,
            'updated_at': DateTime.now().toIso8601String(),
            'start_time': DateTime.now().toIso8601String(),
          })
          .eq('id', rideRequestId)
          .eq('driver_id', driverId);

      debugPrint('✅ Trip started successfully');
    } catch (e) {
      debugPrint('❌ Error starting trip: $e');
      throw Exception('Failed to start trip: $e');
    }
  }
}
