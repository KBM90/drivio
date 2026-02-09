import 'dart:async';
import 'package:drivio_app/delivery_person/services/delivery_person_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider for tracking delivery person location during active deliveries
class DeliveryPersonLocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  Timer? _locationUpdateTimer;
  bool _isTrackingActive = false;
  int? _activeDeliveryId;

  Position? get currentPosition => _currentPosition;
  LatLng? get currentLocation =>
      _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;
  bool get isTrackingActive => _isTrackingActive;
  int? get activeDeliveryId => _activeDeliveryId;

  /// Start tracking location for an active delivery
  /// Updates location every 10 seconds
  /// Optionally set initial status (defaults to 'accepted')
  Future<void> startTracking(
    int deliveryId, {
    String initialStatus = 'accepted',
  }) async {
    if (_isTrackingActive && _activeDeliveryId == deliveryId) {
      debugPrint('⚠️ Already tracking delivery #$deliveryId');
      return;
    }

    debugPrint('🚀 Starting location tracking for delivery #$deliveryId');
    _activeDeliveryId = deliveryId;
    _isTrackingActive = true;

    // Update delivery request status
    await updateDeliveryStatus(initialStatus);

    notifyListeners();

    // Update location immediately
    await _updateLocation();

    // Set up periodic updates every 10 seconds
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (
      _,
    ) async {
      await _updateLocation();
    });
  }

  /// Stop tracking location and mark delivery as completed
  Future<void> stopTracking() async {
    debugPrint(
      '🛑 Stopping location tracking for delivery #$_activeDeliveryId',
    );
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    _isTrackingActive = false;

    final deliveryId = _activeDeliveryId;
    _activeDeliveryId = null;

    // Mark delivery as completed if there was an active delivery
    if (deliveryId != null) {
      await updateDeliveryStatus('completed', deliveryId: deliveryId);
    }

    notifyListeners();
  }

  /// Update delivery request status during active delivery
  /// Valid statuses: accepted, picking_up, picked_up, delivering, completed
  Future<void> updateDeliveryStatus(String status, {int? deliveryId}) async {
    try {
      final targetDeliveryId = deliveryId ?? _activeDeliveryId;
      if (targetDeliveryId == null) {
        debugPrint('❌ No active delivery to update status');
        return;
      }

      // Update delivery_requests.status
      await Supabase.instance.client
          .from('delivery_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', targetDeliveryId);

      debugPrint('✅ Delivery #$targetDeliveryId status updated to: $status');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating delivery status: $e');
    }
  }

  /// Update current location and send to server during active tracking
  Future<void> _updateLocation() async {
    try {
      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Check if position has changed significantly (at least 5 meters)
      if (_currentPosition != null) {
        double distanceMoved = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distanceMoved < 5) {
          debugPrint('📍 Position change too small, skipping update');
          return;
        }
      }

      _currentPosition = position;

      // Update location in Supabase
      await DeliveryPersonService.updateDeliveryPersonLocation(
        position.latitude,
        position.longitude,
      );

      debugPrint(
        '✅ Location updated for delivery #$_activeDeliveryId: '
        '(${position.latitude}, ${position.longitude})',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating delivery person location: $e');
    }
  }

  /// Update current location once (for app startup)
  /// This updates the delivery person's location in the database without starting continuous tracking
  Future<void> updateCurrentLocation() async {
    try {
      debugPrint('📍 Updating delivery person current location...');

      // Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied forever');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _currentPosition = position;

      // Update location in Supabase
      await DeliveryPersonService.updateDeliveryPersonLocation(
        position.latitude,
        position.longitude,
      );

      debugPrint(
        '✅ Current location updated: (${position.latitude}, ${position.longitude})',
      );

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error updating current location: $e');
    }
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}
