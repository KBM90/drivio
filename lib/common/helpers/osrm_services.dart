import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    LatLng driverLocation,
    LatLng destinationLocation,
  ) async {
    final url =
        '$osrmBaseUrl/${driverLocation.longitude},${driverLocation.latitude};'
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
}
