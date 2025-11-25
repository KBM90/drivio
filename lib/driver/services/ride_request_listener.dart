import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class RideRequestListener {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  double? driverRange;
  int? _driverId;
  double? _driverLat;
  double? _driverLng;

  bool get isListening => _channel != null;

  /// Start listening for nearby ride requests
  Future<void> startListening({
    required Function(List<Map<String, dynamic>>) onNearbyRideRequests,
    required Function(String) onError,
  }) async {
    try {
      // Get current driver info
      final driverInfo = await _getDriverInfo();
      if (driverInfo == null) {
        onError('Driver not found');
        return;
      }

      _driverId = driverInfo['id'];
      driverRange = driverInfo['range'];
      _driverLat = driverInfo['latitude'];
      _driverLng = driverInfo['longitude'];

      if (_driverLat == null || _driverLng == null) {
        onError('Driver location not available');
        return;
      }

      // Fetch initial nearby rides
      await _fetchNearbyRides(onNearbyRideRequests, onError);

      // Subscribe to real-time changes
      _channel =
          _supabase
              .channel('ride_requests_channel')
              .onPostgresChanges(
                event: PostgresChangeEvent.insert,
                schema: 'public',
                table: 'ride_requests',
                callback: (payload) async {
                  debugPrint(
                    '🔔 New ride request inserted: ${payload.newRecord}',
                  );
                  await _fetchNearbyRides(onNearbyRideRequests, onError);
                },
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.update,
                schema: 'public',
                table: 'ride_requests',
                callback: (payload) async {
                  debugPrint('🔄 Ride request updated: ${payload.newRecord}');
                  await _fetchNearbyRides(onNearbyRideRequests, onError);
                },
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.delete,
                schema: 'public',
                table: 'ride_requests',
                callback: (payload) async {
                  debugPrint('🗑️ Ride request deleted: ${payload.oldRecord}');
                  await _fetchNearbyRides(onNearbyRideRequests, onError);
                },
              )
              .subscribe();

      debugPrint(
        '✅ Started listening for ride requests within $driverRange km',
      );
    } catch (e) {
      debugPrint('❌ Error starting listener: $e');
      onError(e.toString());
    }
  }

  /// Fetch nearby ride requests based on driver location and range
  Future<void> _fetchNearbyRides(
    Function(List<Map<String, dynamic>>) onNearbyRideRequests,
    Function(String) onError,
  ) async {
    try {
      if (_driverLat == null || _driverLng == null || driverRange == null) {
        onError('Driver location or range not available');
        return;
      }

      // Convert range from km to meters for PostGIS
      final rangeInMeters = driverRange! * 1000;

      // Query ride requests within range using PostGIS ST_DWithin
      final response = await _supabase.rpc(
        'get_nearby_ride_requests',
        params: {
          'driver_lat': _driverLat,
          'driver_lng': _driverLng,
          'range_meters': rangeInMeters,
        },
      );

      final nearbyRides = List<Map<String, dynamic>>.from(response as List);

      debugPrint('📍 Found ${nearbyRides.length} nearby ride requests');
      onNearbyRideRequests(nearbyRides);
    } catch (e) {
      debugPrint('❌ Error fetching nearby rides: $e');
      onError(e.toString());
    }
  }

  /// Get current driver information including location and range
  Future<Map<String, dynamic>?> _getDriverInfo() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // Get internal user ID
      final userResponse =
          await _supabase
              .from('users')
              .select('id')
              .eq('user_id', userId)
              .single();

      final internalUserId = userResponse['id'] as int;

      // Get driver info with location
      final driverResponse =
          await _supabase
              .from('drivers')
              .select('id, location, range, status')
              .eq('user_id', internalUserId)
              .single();

      // Extract coordinates from PostGIS POINT
      final locationStr = driverResponse['location'] as String;
      final coords = GeolocatorHelper.parsePostGISPoint(locationStr);

      return {
        'id': driverResponse['id'],
        'range': driverResponse['range'],
        'latitude': coords['latitude'],
        'longitude': coords['longitude'],
        'status': driverResponse['status'],
      };
    } catch (e) {
      debugPrint('❌ Error getting driver info: $e');
      return null;
    }
  }

  

  /// Stop listening for ride requests
  Future<void> stopListening() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
      debugPrint('🛑 Stopped listening for ride requests');
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
  }

  /// Refresh driver data (range and other info)
  Future<void> refreshDriverData() async {
    try {
      debugPrint('🔄 Refreshing driver data...');

      Driver? driver = await DriverService.getDriver();

      // Update internal state
      _driverId = driver.id;
      driverRange = driver.range?.toDouble() ?? 10.0;

      // Update driver location if available
      if (driver.location?.latitude != null &&
          driver.location?.longitude != null) {
        _driverLat = driver.location?.latitude;
        _driverLng = driver.location?.longitude;
      }

      debugPrint(
        '✅ Driver data refreshed: Range=$driverRange km, Location=($_driverLat, $_driverLng)',
      );
    } catch (e) {
      debugPrint('❌ Error refreshing driver data: $e');
      rethrow;
    }
  }
}
