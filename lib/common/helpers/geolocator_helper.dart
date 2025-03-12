import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GeolocatorHelper {
  /// Checks and requests location permission
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Fetches the current position of the user
  static Future<LatLng?> getCurrentLocation() async {
    bool hasPermission = await checkLocationPermission();
    if (!hasPermission) return null;

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );

    return LatLng(position.latitude, position.longitude);
  }
}
