import 'dart:math';

import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' show parse;

import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geo;

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
    try {
      final String url =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng";

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "User-Agent": "Drivio", // Required by Nominatim API
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return getValidPlaceName(data);
      } else {
        debugPrint("⚠️ Nominatim API returned status: ${response.statusCode}");
        return "Location unavailable";
      }
    } catch (e) {
      debugPrint("❌ Error fetching place name: $e");
      // Return a fallback message instead of throwing
      return "Location unavailable";
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
    try {
      // 1. Try native geocoding first
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        lat,
        lng,
      );
      if (placemarks.isNotEmpty) {
        return placemarks.first.isoCountryCode;
      }
    } catch (e) {
      debugPrint("⚠️ Native geocoding failed: $e");
      debugPrint("🔄 Attempting fallback to Photon API...");

      try {
        // 2. Fallback to Photon API
        final url = "https://photon.komoot.io/reverse?lat=$lat&lon=$lng";
        final response = await http
            .get(Uri.parse(url), headers: {"User-Agent": "Drivio"})
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final features = data['features'] as List;
          if (features.isNotEmpty) {
            final props = features.first['properties'];
            final countryCode = props['countrycode'] as String?;
            if (countryCode != null) {
              return countryCode.toUpperCase();
            }
          }
        }
      } catch (fallbackError) {
        debugPrint("❌ Fallback geocoding also failed: $fallbackError");
      }
    }
    return null;
  }

  Future<String?> getCityFromCoordinates(double lat, double lng) async {
    // 1. Try Nominatim first
    try {
      final String url =
          "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng";

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "User-Agent": "Drivio", // Required by Nominatim API
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          if (address['city'] != null) {
            debugPrint("✅ City fetched from Nominatim: ${address['city']}");
            return address['city'];
          }
          if (address['town'] != null) {
            debugPrint("✅ Town fetched from Nominatim: ${address['town']}");
            return address['town'];
          }
          if (address['village'] != null) {
            debugPrint(
              "✅ Village fetched from Nominatim: ${address['village']}",
            );
            return address['village'];
          }
        }
      } else {
        debugPrint("⚠️ Nominatim returned status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Nominatim failed: $e");
      debugPrint("🔄 Trying Photon API fallback...");
    }

    // 2. Fallback to Photon reverse geocoding
    try {
      final String url = "https://photon.komoot.io/reverse?lat=$lat&lon=$lng";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List?;

        if (features != null && features.isNotEmpty) {
          final properties = features[0]['properties'] as Map<String, dynamic>?;

          if (properties != null) {
            if (properties['city'] != null) {
              debugPrint("✅ City fetched from Photon: ${properties['city']}");
              return properties['city'];
            }
            if (properties['town'] != null) {
              debugPrint("✅ Town fetched from Photon: ${properties['town']}");
              return properties['town'];
            }
            if (properties['village'] != null) {
              debugPrint(
                "✅ Village fetched from Photon: ${properties['village']}",
              );
              return properties['village'];
            }
          }
        }
      } else {
        debugPrint("⚠️ Photon returned status ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Photon fallback also failed: $e");
    }

    debugPrint("❌ Could not fetch city from any geocoding service");
    return null;
  }

  Future<List<Map<String, dynamic>>> searchPlaces(
    String query, {
    double? lat,
    double? lon,
    String? countryCode,
    double radiusKm = 20.0, // Default 20km radius (reduced from 50km)
  }) async {
    // 1. Use Nominatim API with viewbox for bounded search
    try {
      String url =
          "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=50";

      if (countryCode != null) {
        url += "&countrycodes=$countryCode";
      }

      // Add viewbox for bounded search (more reliable than Photon)
      if (lat != null && lon != null) {
        final bbox = _calculateBoundingBox(lat, lon, radiusKm);
        // Nominatim viewbox format: left,top,right,bottom (lonMin,latMax,lonMax,latMin)
        url +=
            "&viewbox=${bbox['lonMin']},${bbox['latMax']},${bbox['lonMax']},${bbox['latMin']}";
        url += "&bounded=1"; // STRICT: Only return results within viewbox
      } else {
        debugPrint(
          "⚠️ WARNING: No user location provided! Results will not be filtered by distance.",
        );
      }

      debugPrint("🔍 Searching Nominatim: $url");

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "User-Agent": "Drivio", // Required by Nominatim
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        debugPrint("📍 Nominatim returned ${data.length} results");

        // Calculate distance for each result
        final resultsWithDistance =
            data.map((item) {
              final itemLat = double.parse(item['lat'].toString());
              final itemLon = double.parse(item['lon'].toString());

              double distance = double.infinity;
              if (lat != null && lon != null) {
                distance = _calculateDistance(lat, lon, itemLat, itemLon);
              }

              return {'item': item, 'distance': distance};
            }).toList();

        // ✅ Filter by distance (only keep results within radius)
        final nearbyResults =
            resultsWithDistance.where((item) {
              final distance = item['distance'] as double;
              return distance <= radiusKm;
            }).toList();

        debugPrint("📏 Within ${radiusKm}km: ${nearbyResults.length} results");

        // ✅ Fallback: If very few results within radius, expand to 2x radius
        List<Map<String, dynamic>> finalResults = nearbyResults;
        if (nearbyResults.length < 3 && resultsWithDistance.isNotEmpty) {
          final expandedResults =
              resultsWithDistance.where((item) {
                final distance = item['distance'] as double;
                return distance <= radiusKm * 2; // Expand to 2x radius
              }).toList();

          if (expandedResults.length > nearbyResults.length) {
            debugPrint(
              "⚠️ Expanding search to ${radiusKm * 2}km (found ${expandedResults.length} results)",
            );
            finalResults = expandedResults;
          }
        }

        // Sort by distance (nearest first)
        finalResults.sort((a, b) {
          final distA = a['distance'] as double;
          final distB = b['distance'] as double;
          return distA.compareTo(distB);
        });

        // Take top 5 nearest results
        final topFeatures =
            finalResults.take(5).map((item) => item['item']).toList();

        if (topFeatures.isEmpty) {
          debugPrint("❌ No results found after all filtering");
        }

        return topFeatures.map((item) {
          final address = item['address'] as Map<String, dynamic>?;

          String name = item['name'] ?? item['display_name'].split(',')[0];

          // Build display name
          List<String> displayParts = [];
          if (item['name'] != null && item['name'].toString().isNotEmpty) {
            displayParts.add(item['name']);
          }
          if (address != null) {
            if (address['road'] != null) displayParts.add(address['road']);
            if (address['city'] != null) {
              displayParts.add(address['city']);
            } else if (address['town'] != null) {
              displayParts.add(address['town']);
            } else if (address['village'] != null) {
              displayParts.add(address['village']);
            }
          }

          String displayName =
              displayParts.isNotEmpty
                  ? displayParts.toSet().join(', ')
                  : item['display_name'];

          return {
            'name': name,
            'display_name': displayName,
            'lat': double.parse(item['lat'].toString()),
            'lon': double.parse(item['lon'].toString()),
            'type': item['type'],
            'osm_key': item['class'],
          };
        }).toList();
      }
    } catch (e) {
      debugPrint("⚠️ Photon API failed: $e");
      debugPrint("🔄 Switching to Nominatim Fallback...");
    }

    // 2. Fallback to Nominatim API
    return _searchPlacesNominatim(
      query,
      lat: lat,
      lon: lon,
      countryCode: countryCode,
    );
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Calculates a bounding box around a center point with given radius in km
  /// Returns a Map with lonMin, latMin, lonMax, latMax
  Map<String, double> _calculateBoundingBox(
    double lat,
    double lon,
    double radiusKm,
  ) {
    // Earth's radius in km
    const double earthRadiusKm = 6371.0;

    // Convert radius to radians
    final double radDist = radiusKm / earthRadiusKm;

    // Convert lat/lon to radians
    final double latRad = _degreesToRadians(lat);
    final double lonRad = _degreesToRadians(lon);

    // Calculate bounding box
    final double latMin = latRad - radDist;
    final double latMax = latRad + radDist;

    // Longitude calculation needs to account for latitude
    final double deltaLon = asin(sin(radDist) / cos(latRad));
    final double lonMin = lonRad - deltaLon;
    final double lonMax = lonRad + deltaLon;

    // Convert back to degrees
    return {
      'latMin': latMin * 180 / pi,
      'latMax': latMax * 180 / pi,
      'lonMin': lonMin * 180 / pi,
      'lonMax': lonMax * 180 / pi,
    };
  }

  Future<List<Map<String, dynamic>>> _searchPlacesNominatim(
    String query, {
    double? lat,
    double? lon,
    String? countryCode,
  }) async {
    try {
      String url =
          "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=10";

      if (countryCode != null) {
        url += "&countrycodes=$countryCode";
      }

      // Nominatim doesn't support simple lat/lon bias in search URL same way as Photon
      // But we can use viewbox if we wanted, for now simple search is better than nothing.

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "User-Agent": "Drivio", // Required by Nominatim APIPolicy
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        return data.take(5).map((item) {
          final address = item['address'] as Map<String, dynamic>?;

          String name = item['name'] ?? "";
          if (name.isEmpty && address != null) {
            name =
                address['road'] ??
                address['city'] ??
                item['display_name'].split(',')[0];
          }

          return {
            'name': name,
            'display_name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
            'type': item['type'], // e.g. "residential"
            'osm_key': item['class'], // e.g. "highway"
          };
        }).toList();
      } else {
        debugPrint(
          "❌ Nominatim API return non-200 status: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("❌ Nominatim Fallback failed: $e");
    }

    return [];
  }

  /// Search for cities by name, optionally filtered by country code
  /// Search for cities by name, optionally filtered by country code
  Future<List<String>> searchCities(
    String query, {
    String? countryCode,
    double? lat,
    double? lon,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      // URL encode the query to handle special characters properly
      final encodedQuery = Uri.encodeComponent(query);

      String url =
          "https://photon.komoot.io/api/?q=$encodedQuery&osm_tag=place:city&osm_tag=place:town&limit=10";

      if (lat != null && lon != null) {
        url += "&lat=$lat&lon=$lon";
      }

      final response = await http
          .get(Uri.parse(url), headers: {"User-Agent": "Drivio"})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        final cities = <String>{};

        for (var feature in features) {
          final props = feature['properties'];
          final featureCountryCode = props['countrycode'] as String?;
          String? name = props['name'] as String?;

          // Filter by country code if provided
          if (countryCode != null && countryCode.isNotEmpty) {
            if (featureCountryCode == null ||
                featureCountryCode.toLowerCase() != countryCode.toLowerCase()) {
              continue;
            }
          }

          // Clean the name to get only the Latin/Western script part
          if (name != null) {
            // Updated regex to include Latin Extended characters (accented letters)
            // This matches: a-z, A-Z, accented characters (À-ÿ), spaces, hyphens, apostrophes
            final latinRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\-']+");
            final match = latinRegex.firstMatch(name);
            if (match != null) {
              name = match.group(0)?.trim();
            }
          }

          if (name != null && name.trim().isNotEmpty) {
            cities.add(name);
          }
        }

        final result = cities.take(5).toList();
        return result;
      } else {
        debugPrint('⚠️ API returned non-200 status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("❌ Error searching cities: $e");
    }
    return [];
  }

  String normalizeCity(String city) {
    // Remove diacritics/accents and convert to lowercase
    const withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String result = city;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }

    return result.toLowerCase().trim();
  }
}
