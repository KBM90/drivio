import 'package:drivio_app/driver/models/ride_request.dart';
import 'package:drivio_app/driver/services/ride_request_services.dart';
import 'package:flutter/material.dart';

class RideRequestsProvider with ChangeNotifier {
  List<RideRequest> _rideRequests = [];
  bool _isLoading = false;

  List<RideRequest> get rideRequests => _rideRequests;
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
}
