import 'dart:async';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DriverLocationProvider extends ChangeNotifier {
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;

  LatLng? get currentLocation => _currentLocation;

  DriverLocationProvider() {
    _startListening();
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
        if (_currentLocation != null) {
          double distanceMoved = Geolocator.distanceBetween(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            position.latitude,
            position.longitude,
          );

          if (distanceMoved < 5) {
            return; // Skip API update if movement is less than 5 meters
          }
        }

        _currentLocation = LatLng(position.latitude, position.longitude);

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

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
