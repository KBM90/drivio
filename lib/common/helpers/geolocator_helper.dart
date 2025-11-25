import 'package:drivio_app/common/models/location.dart';
import 'package:flutter/cupertino.dart';
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

  static Position latLngToPosition(LatLng latLng) {
    return Position(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      timestamp: DateTime.now(), // Current timestamp
      accuracy: 0.0, // Default accuracy (unknown)
      altitude: 0.0, // Default altitude
      heading: 0.0, // Default heading
      speed: 0.0, // Default speed
      speedAccuracy: 0.0, // Default speed accuracy
      altitudeAccuracy:
          0.0, // Default altitude accuracy (required in newer versions)
      headingAccuracy:
          0.0, // Default heading accuracy (required in newer versions)
    );
  }

  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  static LatLng locationToLatLng(Location? position) {
    return LatLng(position!.latitude!, position.longitude!);
  }

  static Future<double?> calculateDistance(LatLng end) async {
    try {
      LatLng? userCurrentLocation = await getCurrentLocation();
      if (userCurrentLocation == null) {
        return null; // Return null if location cannot be obtained
      }
      return Geolocator.distanceBetween(
        userCurrentLocation.latitude,
        userCurrentLocation.longitude,
        end.latitude,
        end.longitude,
      );
    } catch (e) {
      print('Error calculating distance: $e');
      return null; // Return null on error
    }
  }

  /// Parse PostGIS POINT string to lat/lng
  static Map<String, double> parsePostGISPoint(String pointStr) {
    try {
      if (pointStr.startsWith('POINT')) {
        final coords = pointStr
            .replaceAll('POINT(', '')
            .replaceAll(')', '')
            .split(' ');

        return {
          'longitude': double.parse(coords[0]),
          'latitude': double.parse(coords[1]),
        };
      } else {
        throw Exception('Unsupported location format');
      }
    } catch (e) {
      debugPrint('❌ Error parsing PostGIS point: $e');
      return {'latitude': 0.0, 'longitude': 0.0};
    }
  }

  /// Parse GeoJSON Point to lat/lng (Supabase returns PostGIS as GeoJSON)
  static Map<String, double>? parseGeoJSON(dynamic geoJson) {
    try {
      if (geoJson == null) return null;

      if (geoJson is Map<String, dynamic>) {
        // GeoJSON format: {"type": "Point", "coordinates": [lng, lat]}
        final coordinates = geoJson['coordinates'] as List;
        return {
          'longitude': (coordinates[0] as num).toDouble(),
          'latitude': (coordinates[1] as num).toDouble(),
        };
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error parsing GeoJSON: $e');
      return null;
    }
  }
}
