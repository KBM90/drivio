import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:latlong2/latlong.dart';

class OSRMService {
  static const String osrmBaseUrl = MapConstants.osrmBaseUrl;

  Future<List<LatLng>> getRouteBetweenCoordinates(
    LatLng start,
    LatLng end,
  ) async {
    final url =
        '$osrmBaseUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

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
}
