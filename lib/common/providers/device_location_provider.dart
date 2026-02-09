import 'dart:async';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/delivery_person/services/delivery_person_service.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:drivio_app/passenger/services/passenger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DeviceLocationProvider extends ChangeNotifier {
  Position? _currentPosition; // Change to Position? instead of LatLng?
  StreamSubscription<Position>? _positionStream;
  LatLng? _destination;
  bool _isLoading = false;

  LatLng? get currentLocation =>
      _currentPosition != null
          ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
          : null;
  Position? get currentPosition => _currentPosition; // Add getter for Position
  LatLng? get destination => _destination;
  bool get isLoading => _isLoading;

  DeviceLocationProvider() {
    getCurrentLocation();
    _startListening();
  }
  Future<void> getCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      LatLng? location = await GeolocatorHelper.getCurrentLocation();

      if (location != null) {
        _currentPosition = GeolocatorHelper.latLngToPosition(location);
      }
    } catch (e) {
      // Optionally handle the error
      print('Error getting location: $e');
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

          if (distanceMoved < 5) {
            return; // Skip API update if movement is less than 5 meters
          }
        }

        _currentPosition = position; // Store the full Position object

        // 🔹 Update location in Supabase based on user role
        final role = await AuthService.getUserRole();

        if (role == 'driver') {
          await DriverService.updateDriverLocation(
            position.latitude,
            position.longitude,
          );
        } else if (role == 'passenger') {
          await PassengerService.updatePassengerLocation(
            position.latitude,
            position.longitude,
          );
        } else if (role == 'deliveryperson') {
          await DeliveryPersonService.updateDeliveryPersonLocation(
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

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
