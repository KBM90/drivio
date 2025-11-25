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
    BuildContext context,
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
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<String> getPlaceName(double? lat, double? lng) async {
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
    bool isValid(String? value) {
      return value != null && value.trim().isNotEmpty;
    }

    final address = data['address'] as Map<String, dynamic>?;

    if (address != null) {
      // 1. Try Street + House Number
      if (isValid(address['road'])) {
        if (isValid(address['house_number'])) {
          return "${address['road']}, ${address['house_number']}";
        }
        return address['road'];
      }

      // 2. Try Pedestrian / Footway
      if (isValid(address['pedestrian'])) {
        return address['pedestrian'];
      }

      // 3. Try Suburb / Neighbourhood
      if (isValid(address['suburb'])) {
        return address['suburb'];
      }
      if (isValid(address['neighbourhood'])) {
        return address['neighbourhood'];
      }

      // 4. Try City / Town / Village
      if (isValid(address['city'])) {
        return address['city'];
      }
      if (isValid(address['town'])) {
        return address['town'];
      }
      if (isValid(address['village'])) {
        return address['village'];
      }
    }

    // 5. Fallback to display_name (truncated) or name
    if (isValid(data['display_name'])) {
      final parts = data['display_name'].toString().split(',');
      if (parts.length >= 2) {
        return "${parts[0].trim()}, ${parts[1].trim()}";
      }
      return parts[0].trim();
    }

    if (isValid(data['name'])) {
      return data['name'];
    }

    return "Unknown location";
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
        // round to 1 decimal place
        return double.parse(durationInMinutes.toStringAsFixed(1));
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

  Future<String> getFormattedDuration(
    LatLng startLocation,
    LatLng destinationLocation,
  ) async {
    final durationInMinutes = await getDuration(
      startLocation,
      destinationLocation,
    );

    if (durationInMinutes < 60) {
      // Less than 60 minutes: show as "X min"
      return '${durationInMinutes.round()} min';
    } else {
      // 60 minutes or more: show as "X h Y min"
      final hours = (durationInMinutes / 60).floor();
      final minutes = (durationInMinutes % 60).round();

      if (minutes == 0) {
        return '$hours h';
      } else {
        return '$hours h $minutes min';
      }
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

  Future<String?> getCountryCode(double lat, double lng) async {
    final String url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng";
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"User-Agent": "Drivio"},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['address']['country_code'];
      }
    } catch (e) {
      debugPrint("Error fetching country code: $e");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchPlaces(
    String query, {
    double? lat,
    double? lon,
    String? countryCode,
  }) async {
    // Request more results to allow for filtering
    String url = "https://photon.komoot.io/api/?q=$query&limit=20";
    if (lat != null && lon != null) {
      url += "&lat=$lat&lon=$lon";
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        // Filter by country code if provided
        final filteredFeatures =
            countryCode != null
                ? features.where((f) {
                  final props = f['properties'];
                  final cc = props['countrycode'] as String?;
                  return cc != null &&
                      cc.toLowerCase() == countryCode.toLowerCase();
                }).toList()
                : features;

        // Take top 5
        final topFeatures = filteredFeatures.take(5).toList();

        return topFeatures.map((feature) {
          final properties = feature['properties'];
          final geometry = feature['geometry'];
          final coordinates = geometry['coordinates'] as List;

          String name =
              properties['name'] ??
              properties['city'] ??
              properties['street'] ??
              "Unknown";

          // Construct a display name
          List<String> displayParts = [];
          if (properties['name'] != null) displayParts.add(properties['name']);
          if (properties['street'] != null)
            displayParts.add(properties['street']);
          if (properties['city'] != null) displayParts.add(properties['city']);
          if (properties['country'] != null)
            displayParts.add(properties['country']);

          String displayName = displayParts.toSet().join(
            ', ',
          ); // Remove duplicates

          return {
            'name': name,
            'display_name': displayName,
            'lat': coordinates[1].toString(),
            'lon': coordinates[0].toString(),
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("Error searching places: $e");
    }
    return [];
  }
}
