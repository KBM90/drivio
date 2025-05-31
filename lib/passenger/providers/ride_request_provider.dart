import 'package:drivio_app/driver/models/ride_request.dart';
import 'package:drivio_app/passenger/services/ride_request_services.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class RideRequestProvider extends ChangeNotifier {
  String? _pickupLocation;
  String? _destination;
  String? _rideType;
  String? _paymentMethod;
  double? _estimatedFare;
  String? _operationMessage;
  RideRequest? _currentRideRequest;

  String? get pickupLocation => _pickupLocation;
  String? get destination => _destination;
  String? get rideType => _rideType;
  String? get paymentMethod => _paymentMethod;
  double? get estimatedFare => _estimatedFare;
  String? get operationMessage => _operationMessage;
  RideRequest? get currentRideRequest => _currentRideRequest;

  Future<String> createRequest({
    required LatLng pickup,
    required LatLng destination,
    required transportTypeId,
    required price,
    required paymentMethodId,
  }) async {
    try {
      return await RideRequestServices.createRideRequest(
        pickup: pickup,
        destination: destination,
        transportTypeId: transportTypeId,
        price: price,
        paymentMethodId: paymentMethodId,
      );
    } catch (e) {
      debugPrint('Error creating ride request: $e');
      rethrow;
    }
  }

  Future<void> fetchCurrentRideRequest() async {
    try {
      final rideRequest = await RideRequestServices.fetchCurrentRideRequest();

      if (rideRequest != null) {
        _currentRideRequest = rideRequest;
      } else {
        _currentRideRequest = null;
      }
      print(rideRequest);

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching current ride request: $e');
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

  void resetRideRequest() {
    _pickupLocation = null;
    _destination = null;
    _rideType = null;
    _paymentMethod = null;
    _estimatedFare = null;
    notifyListeners();
  }
}
