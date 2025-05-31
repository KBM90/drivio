import 'dart:math';

import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' show parse;

import 'package:latlong2/latlong.dart';

class OSRMService {
  static const String osrmBaseUrl = MapConstants.osrmBaseUrl;

  Future<List<LatLng>> getRouteBetweenCoordinates(
    LatLng driver,
    LatLng pickup,
    LatLng dropoff,
  ) async {
    final url =
        '$osrmBaseUrl/${driver.longitude},${driver.latitude};'
        '${pickup.longitude},${pickup.latitude};'
        '${dropoff.longitude},${dropoff.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return route['geometry']['coordinates']
              .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
              .toList();
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('Failed to load route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }

  Future<List<LatLng>> getRouteBetweenPickupAndDropoff(
    LatLng pickup,
    LatLng dropoff,
  ) async {
    final url =
        '$osrmBaseUrl/${pickup.longitude},${pickup.latitude};'
        '${dropoff.longitude},${dropoff.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return route['geometry']['coordinates']
              .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
              .toList();
        } else {
          throw Exception('No route found');
        }
      } else {
        throw Exception('Failed to load route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching route: $e');
    }
  }

  Future<String> getPlaceName(double lat, double lng) async {
    final String url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "User-Agent": "Drivio", // Required by Nominatim API
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return getValidPlaceName(data);
    } else {
      return "Error fetching location";
    }
  }

  Future<String> getPlaceNameFromGoogleMaps(double lat, double lng) async {
    final String url =
        "https://www.google.com/maps/@$lat,$lng,17z?entry=ttu&g_ep=EgoyMDI1MDQwOS4wIKXMDSoASAFQAw%3D%3D";

    try {
      final response = await http.get(Uri.parse(url));
      print(response.body);
      if (response.statusCode == 200) {
        // Parse the HTML content
        var document = parse(response.body);
        // Extract the place name (example: from the <title> tag)
        var titleElement = document.querySelector('title');
        String title = titleElement?.text ?? "Unknown location";

        // The title might be something like "Nador, Oriental, Morocco - Google Maps"
        // Clean it up to remove the "- Google Maps" suffix
        return title.replaceAll(" - Google Maps", "").trim();
      } else {
        return "Error fetching location";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  String getValidPlaceName(Map<String, dynamic> data) {
    // Helper function to check if a string is valid (not null & not empty)
    bool isValid(String? value) {
      return value != null && value.trim().isNotEmpty;
    }

    if (isValid(data['name'])) {
      return data['addresstype'] + data['name'];
    } else if (isValid(data['address']?['residential'])) {
      return data['address']?['residential'];
    } else if (isValid(data['address']?['town'])) {
      return data['address']?['town'];
    } else {
      return "Unknown location"; // ✅ Now properly placed in return statement
    }
  }

  // In your osrm_services.dart file
  Future<Map<String, dynamic>> getTimeAndDistanceToPickup(
    LatLng startLocation,
    LatLng destinationLocation,
  ) async {
    final url =
        '$osrmBaseUrl/${startLocation.longitude},${startLocation.latitude};'
        '${destinationLocation.longitude},${destinationLocation.latitude}' // Note: longitude first in OSRM
        '?overview=false&annotations=duration,distance';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final duration = (data['routes'][0]['duration']) / 196024; // in minutes
        final distance = data['routes'][0]['distance'] / 1000; // in km

        return {'duration': duration, 'distance': distance};
      } else {
        throw Exception('Failed to load route data');
      }
    } catch (e) {
      debugPrint('Error getting time/distance to pickup: $e');
      return {'duration': 0, 'distance': 0};
    }
  }

  Future<double> getDistance(
    LatLng startLocation,
    LatLng destinationLocation,
  ) async {
    final url =
        '$osrmBaseUrl/${startLocation.longitude},${startLocation.latitude};'
        '${destinationLocation.longitude},${destinationLocation.latitude}'
        '?overview=false&annotations=distance';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final distance = data['routes'][0]['distance'] / 1000; // in kilometers
        return distance;
      } else {
        throw Exception('Failed to load route data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting distance to pickup: $e');
      return 0.0;
    }
  }

  Future<double> getDuration(
    LatLng startLocation,
    LatLng destinationLocation,
  ) async {
    final url =
        '$osrmBaseUrl/${startLocation.longitude},${startLocation.latitude};'
        '${destinationLocation.longitude},${destinationLocation.latitude}'
        '?overview=false';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // duration is in seconds, we convert it to minutes
        final durationInSeconds = data['routes'][0]['duration'];
        final durationInMinutes = durationInSeconds / 60.0;
        return durationInMinutes;
      } else {
        throw Exception(
          'Failed to load route duration: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting duration: $e');
      return 0.0;
    }
  }

  List<LatLng> squareAround(LatLng center, double sideMeters) {
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng = 111320.0 * cos(center.latitude * pi / 180);

    final dLat = (sideMeters / 2) / metersPerDegreeLat;
    final dLng = (sideMeters / 2) / metersPerDegreeLng;

    return [
      LatLng(center.latitude - dLat, center.longitude - dLng),
      LatLng(center.latitude - dLat, center.longitude + dLng),
      LatLng(center.latitude + dLat, center.longitude + dLng),
      LatLng(center.latitude + dLat, center.longitude - dLng),
    ];
  }
}
