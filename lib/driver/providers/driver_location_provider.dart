import 'dart:async';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DriverLocationProvider extends ChangeNotifier {
  Position? _currentPosition; // Change to Position? instead of LatLng?
  StreamSubscription<Position>? _positionStream;
  LatLng? _destination;

  LatLng? get currentLocation =>
      _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;
  Position? get currentPosition => _currentPosition; // Add getter for Position
  LatLng? get destination => _destination;

  DriverLocationProvider() {
    getCurrentLocation();
    _startListening();
  }
  Future<void> getCurrentLocation() async {
    LatLng? location = await GeolocatorHelper.getCurrentLocation();

    _currentPosition = GeolocatorHelper.latLngToPosition(location!);

    notifyListeners();
  }

  void _startListening() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied.");
        return;
      }
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update location every 5 meters
      ),
    ).listen((Position position) async {
      try {
        // Avoid unnecessary API calls for minor position changes
        if (_currentPosition != null) {
          double distanceMoved = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          if (distanceMoved < 5) {
            return; // Skip API update if movement is less than 5 meters
          }
        }

        _currentPosition = position; // Store the full Position object

        // 🔹 Ensure the API call doesn't block UI updates
        await DriverService.updateDriverLocation(
          position.latitude,
          position.longitude,
        );

        notifyListeners();
      } catch (e) {
        print("Error updating location: $e");
      }
    });
  }

  Future<void> getDestination(LatLng passengerDestination) async {
    await DriverService.updateDriverDropOffLocation(
      passengerDestination.latitude,
      passengerDestination.longitude,
    );
    _destination = passengerDestination;
    notifyListeners();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
