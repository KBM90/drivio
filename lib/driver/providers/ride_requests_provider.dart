import 'package:drivio_app/driver/models/ride_request.dart';
import 'package:drivio_app/driver/services/ride_request_services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideRequestsProvider with ChangeNotifier {
  List<RideRequest> _rideRequests = [];

  RideRequest? _currentRideRequest;

  bool _isLoading = true;

  List<RideRequest> get rideRequests => _rideRequests;

  RideRequest? get currentRideRequest => _currentRideRequest;

  bool get isLoading => _isLoading;

  RideRequestsProvider() {
    fetchRideRequests();
  }

  Future<void> fetchRideRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      _rideRequests = await RideRequestService.getRideRequests();
    } catch (e) {
      debugPrint("Error fetching ride requests: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRideRequest(int id) async {
    _isLoading = true;
    notifyListeners();
    print("fetchRideRequest");
    try {
      // 1. Check local list first
      try {
        _currentRideRequest = _rideRequests.firstWhere(
          (request) => request.id == id,
        );
      } catch (_) {
        // 2. If not found locally, fetch from server
        _currentRideRequest = await RideRequestService.getRideRequest(id);
        if (_currentRideRequest != null) {
          _rideRequests.add(_currentRideRequest!); // Update local cache
        }
      }

      // 3. Only store in SharedPreferences if the ride exists
      if (_currentRideRequest != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currentRideId', id);
      } else {
        debugPrint("Ride request $id not found locally or on server.");
      }
    } catch (e) {
      debugPrint("Error fetching ride request $id: $e");
      _currentRideRequest = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPersistanceRideRequest() async {
    print("fetchPersistanceRideRequest");
    _isLoading = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    int? rideId = prefs.getInt("currentRideId");

    if (rideId == null) {
      debugPrint("No ride ID found in SharedPreferences.");
      _currentRideRequest = null;
      notifyListeners();
      return;
    }

    try {
      _currentRideRequest = await RideRequestService.getRideRequest(rideId);

      // 🔹 Check for null instead of 0.0
      if (_currentRideRequest == null ||
          _currentRideRequest!.pickupLocation.latitude == 0.0 ||
          _currentRideRequest!.destinationLocation.latitude == 0.0) {
        debugPrint("Invalid ride data: missing location coordinates.");
        _currentRideRequest = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching ride: $e");
      _currentRideRequest = null;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
