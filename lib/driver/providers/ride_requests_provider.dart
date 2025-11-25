import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/driver/services/ride_request_services.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RideRequestsProvider with ChangeNotifier {
  List<RideRequest> _rideRequests = [];

  RideRequest? _currentRideRequest;

  bool _isLoading = true;

  List<String> pickupPlacesNames = [];
  List<String> destinationPlacesNames = [];

  List<RideRequest> get rideRequests => _rideRequests;

  RideRequest? get currentRideRequest => _currentRideRequest;

  bool get isLoading => _isLoading;

  List<String> get pickupPlaces => pickupPlacesNames;
  List<String> get destinationPlaces => destinationPlacesNames;

  RideRequestsProvider() {
    //fetchRideRequests(driverLocation);
  }

  Future<void> fetchRideRequests(LatLng driverLocation) async {
    _isLoading = true;
    notifyListeners();

    _rideRequests = await RideRequestService.getRideRequests(driverLocation);
    pickupPlacesNames.clear();
    destinationPlacesNames.clear();

    for (var request in _rideRequests) {
      try {
        if (request.pickupLocation.latitude != null &&
            request.pickupLocation.longitude != null) {
          pickupPlacesNames.add(
            await OSRMService().getPlaceName(
              request.pickupLocation.latitude!,
              request.pickupLocation.longitude!,
            ),
          );
        } else {
          pickupPlacesNames.add("Unknown Location");
        }

        if (request.destinationLocation.latitude != null &&
            request.destinationLocation.longitude != null) {
          destinationPlacesNames.add(
            await OSRMService().getPlaceName(
              request.destinationLocation.latitude!,
              request.destinationLocation.longitude!,
            ),
          );
        } else {
          destinationPlacesNames.add("Unknown Location");
        }
      } catch (e) {
        debugPrint("Error fetching place names: $e");
        // Ensure lists stay in sync even on error
        if (pickupPlacesNames.length < _rideRequests.indexOf(request) + 1) {
          pickupPlacesNames.add("Unknown Location");
        }
        if (destinationPlacesNames.length <
            _rideRequests.indexOf(request) + 1) {
          destinationPlacesNames.add("Unknown Location");
        }
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRideRequest(int id) async {
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

  Future<void> acceptRideRequest(
    int id,
    int driverId,
    double latitude,
    double longitude,
  ) async {
    await RideRequestService.acceptRideRequest(id, latitude, longitude);
    await fetchRideRequest(id);
  }
}
