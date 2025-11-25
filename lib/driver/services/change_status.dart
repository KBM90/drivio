import 'package:drivio_app/common/helpers/geolocator_helper.dart';

import 'package:flutter/material.dart';

import 'package:latlong2/latlong.dart';

import 'package:drivio_app/common/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeStatus {
  Future<String?> goOnline() async {
    // Fetch the current location
    final LatLng? currentLocation = await GeolocatorHelper.getCurrentLocation();

    if (currentLocation == null) {
      return 'Unable to fetch current location';
    }

    final driverId = await AuthService.getDriverId();
    if (driverId == null) {
      throw Exception('Driver profile not found');
    }

    try {
      await Supabase.instance.client
          .from('drivers')
          .update({
            'status': 'active',
            'location':
                'POINT(${currentLocation.longitude} ${currentLocation.latitude})',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      return 'You are now online';
    } catch (e) {
      debugPrint('Error going online: $e');
      throw Exception('Failed to go online: $e');
    }
  }

  Future<String?> goOffline() async {
    final driverId = await AuthService.getDriverId();
    if (driverId == null) {
      throw Exception('Driver profile not found');
    }

    try {
      await Supabase.instance.client
          .from('drivers')
          .update({
            'status': 'inactive',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      return 'You are now offline';
    } catch (e) {
      debugPrint('Error going offline: $e');
      throw Exception('Failed to go offline: $e');
    }
  }

  Future<String?> onTrip() async {
    final driverId = await AuthService.getDriverId();
    if (driverId == null) {
      throw Exception('Driver profile not found');
    }

    try {
      await Supabase.instance.client
          .from('drivers')
          .update({
            'status': 'on_trip',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      return 'You are now on a trip';
    } catch (e) {
      debugPrint('Error setting on trip status: $e');
      throw Exception('Failed to set on trip status: $e');
    }
  }

  Future<void> markAsArrived(int rideRequestId) async {
    try {
      await Supabase.instance.client
          .from('ride_requests')
          .update({
            'status': 'arrived',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rideRequestId);

      debugPrint('✅ Ride request marked as arrived');
    } catch (e) {
      debugPrint('❌ Error marking ride as arrived: $e');
      throw Exception('Failed to mark ride as arrived: $e');
    }
  }
}
