import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/passenger/services/ride_request_services.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class PassengerRideRequestProvider extends ChangeNotifier {
  bool _isLoading = false; // ✅ Default to false
  bool _hasFetched = false; // ✅ Track if we have fetched data
  String? _pickupLocation;
  String? _destination;
  String? _rideType;
  String? _paymentMethod;
  double? _estimatedFare;
  String? _operationMessage;
  RideRequest? _currentRideRequest;

  PassengerRideRequestProvider() {
    debugPrint('✨ PassengerRideRequestProvider initialized');
  }

  @override
  void dispose() {
    debugPrint('🗑️ PassengerRideRequestProvider disposed');
    super.dispose();
  }

  // ✅ Add stream subscription for Firestore

  bool get isLoading => _isLoading;
  bool get hasFetched => _hasFetched; // ✅ Getter
  String? get pickupLocation => _pickupLocation;
  String? get destination => _destination;
  String? get rideType => _rideType;
  String? get paymentMethod => _paymentMethod;
  double? get estimatedFare => _estimatedFare;
  String? get operationMessage => _operationMessage;
  RideRequest? get currentRideRequest => _currentRideRequest;

  Future<Map<String, dynamic>> createRequest({
    required LatLng pickup,
    required LatLng destination,
    required transportTypeId,
    required price,
    required paymentMethodId,
    String? instructions, // Add instructions parameter
  }) async {
    try {
      final rideRequestId = await RideRequestServices.createRideRequest(
        pickup: pickup,
        destination: destination,
        transportTypeId: transportTypeId,
        price: price,
        paymentMethodId: paymentMethodId,
        instructions: instructions, // Pass instructions
      );

      // ✅ After creating, fetch and start listening
      await fetchCurrentRideRequest();

      return rideRequestId;
    } catch (e) {
      debugPrint('Error creating ride request: $e');
      rethrow;
    }
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> fetchCurrentRideRequest() async {
    if (_isLoading) return; // ✅ Prevent duplicate calls
    try {
      // Only show loading if we don't have data yet
      if (_currentRideRequest == null) {
        _isLoading = true;
        notifyListeners();
      }

      final rideRequest = await RideRequestServices.getCurrentRideRequest();

      _currentRideRequest = rideRequest;

      if (_currentRideRequest != null) {
        _listenToStatusChanges(_currentRideRequest!.id.toString());
      }

      _isLoading = false;
      _hasFetched = true; // ✅ Mark as fetched
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching current ride request: $e');
      _isLoading = false;
      _hasFetched = true; // ✅ Mark as fetched even on error to stop spinner
      notifyListeners();
    }
  }

  // ✅ Listen to Supabase status changes
  void _listenToStatusChanges(String rideId) {
    // Cancel previous subscription if exists
    _stopListeningToStatus();

    _supabase
        .channel('public:ride_requests:$rideId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'ride_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: rideId,
          ),
          callback: (payload) {
            debugPrint('Ride status update received: ${payload.newRecord}');
            final newStatus = payload.newRecord['status'] as String?;

            if (newStatus != null && _currentRideRequest != null) {
              // ✅ Update the status in current ride request
              _currentRideRequest = _currentRideRequest!.copyWith(
                status: newStatus,
              );

              // ✅ Only set null if ride is really finished or cancelled
              if (newStatus == 'cancelled' || newStatus == 'completed') {
                // Optional: Keep it for a moment to show "Completed" screen or similar
                // For now, we follow the logic of clearing it or handling it in UI
                // If we clear it immediately, the UI might jump to home.
                // Let's just notify. The UI should handle "completed" state.
                // If we want to clear it, we should probably do it after a user action or delay.
                // But the original code cleared it. Let's stick to that for now but maybe with a delay or just clear.
                // Actually, if we clear it, the home screen shows the default UI.
                // Maybe we want to show a "Rate Driver" modal?
                // For now, let's just update status. The UI (RideRequestStatusWidget) should handle the "completed" state.
                if (newStatus == 'cancelled') {
                  _currentRideRequest = null;
                  _stopListeningToStatus();
                }
                // For completed, we might want to keep it to show rating.
              }

              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  // ✅ Stop listening to status changes
  void _stopListeningToStatus() {
    if (_currentRideRequest != null) {
      _supabase.removeChannel(
        _supabase.channel('public:ride_requests:${_currentRideRequest!.id}'),
      );
    }
  }

  Future<void> cancelRideRequest(String reason) async {
    try {
      bool isDone = await RideRequestServices.cancelRideRequest(
        reason,
        _currentRideRequest!.id,
      );
      if (isDone) {
        _currentRideRequest = null;
        _operationMessage = 'Ride request canceled successfully';
        //  _stopListeningToStatus(); // ✅ Stop listening
        notifyListeners();
      } else {
        _operationMessage = 'Failed to cancel ride request.';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error canceling ride request: $e');
    }
  }

  void setPickupLocation(String location) {
    _pickupLocation = location;
    notifyListeners();
  }

  void setDestination(String destination) {
    _destination = destination;
    notifyListeners();
  }

  void setRideType(String rideType) {
    _rideType = rideType;
    notifyListeners();
  }

  void setPaymentMethod(String paymentMethod) {
    _paymentMethod = paymentMethod;
    notifyListeners();
  }

  void setEstimatedFare(double fare) {
    _estimatedFare = fare;
    notifyListeners();
  }
}
