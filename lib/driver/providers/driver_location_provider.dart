import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';

class DriverLocationProvider with ChangeNotifier {
  LatLng? _currentLocation;

  LatLng? get currentLocation => _currentLocation;

  /// Fetch user location and update state
  Future<void> updateLocation() async {
    LatLng? location = await GeolocatorHelper.getCurrentLocation();
    if (location != null) {
      _currentLocation = location;
      notifyListeners(); // 🔔 Notify UI about changes
    }
  }
}
