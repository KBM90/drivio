import 'dart:async';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DriverLocationProvider extends ChangeNotifier {
  Position? _currentPosition; // Change to Position? instead of LatLng?
  StreamSubscription<Position>? _positionStream;
  LatLng? _destination;
  bool _isLoading = false;
  Driver? _currentDriver;

  LatLng? get currentLocation =>
      _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;
  Position? get currentPosition => _currentPosition; // Add getter for Position
  double get heading => _currentPosition?.heading ?? 0.0;
  LatLng? get destination => _destination;
  bool get isLoading => _isLoading;
  Driver? get currentDriver => _currentDriver;

  DriverLocationProvider() {
    getDriver();
    getCurrentLocation();
    _startListening();
  }

  Future<void> getDriver() async {
    _currentDriver = await DriverService.getDriver();
  }

  Future<void> getCurrentLocation() async {
    debugPrint("🔍 DriverLocationProvider.getCurrentLocation() called");
    _isLoading = true;
    notifyListeners();

    try {
      LatLng? location = await GeolocatorHelper.getCurrentLocation();

      if (location != null) {
        _currentPosition = GeolocatorHelper.latLngToPosition(location);
        debugPrint(
          "✅ Location fetched successfully: ${location.latitude}, ${location.longitude}",
        );
      } else {
        debugPrint(
          "⚠️ Location is null - permissions may be denied or location services disabled",
        );
      }
    } catch (e) {
      // Optionally handle the error
      debugPrint('❌ Error getting location in DriverLocationProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

          // Skip if moved less than 5 meters
          if (distanceMoved < 5) {
            return;
          }
        }

        _currentPosition = position; // Store the full Position object

        // Update location in Supabase drivers table only
        // Update location in Supabase drivers table only if driver is loaded
        if (_currentDriver != null) {
          await DriverService.updateDriverLocation(
            position.latitude,
            position.longitude,
          );
        }

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
