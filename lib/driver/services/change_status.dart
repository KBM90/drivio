import 'dart:convert';

import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeStatus {
  Future<String?> goOnline() async {
    // Fetch the current location
    final LatLng? currentLocation = await GeolocatorHelper.getCurrentLocation();

    if (currentLocation == null) {
      throw Exception('Unable to fetch current location');
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    int? driverId = prefs.getInt('current_user_id');
    final response = await http.patch(
      Uri.parse('${Api.baseUrl}/goOnline'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            'Bearer $token', // Add this if using Sanctum token-based auth
      },
      body: jsonEncode({
        'driverId': driverId,
        'location': {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setBool('status', data['status']);

      return data['message']; // Return the success message
    } else if (response.statusCode == 403) {
      // Handle unauthorized access
      final data = jsonDecode(response.body);
      throw Exception(
        data['message'],
      ); // Throw an exception for unauthorized access
    } else if (response.statusCode == 404) {
      // Handle driver not found
      final data = jsonDecode(response.body);
      throw Exception(
        data['message'],
      ); // Throw an exception for driver not found
    } else {
      // Handle other errors
      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    }
  }

  Future<String?> goOffline() async {
    // Fetch the current location
    final LatLng? currentLocation = await GeolocatorHelper.getCurrentLocation();

    if (currentLocation == null) {
      throw Exception('Unable to fetch current location');
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    int? driverId = prefs.getInt('current_user_id');
    final response = await http.patch(
      Uri.parse('${Api.baseUrl}/goOffline'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            'Bearer $token', // Add this if using Sanctum token-based auth
      },
      body: jsonEncode({
        'driverId': driverId,
        'location': {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setBool('status', data['status']);

      return data['message']; // Return the success message
    } else if (response.statusCode == 403) {
      // Handle unauthorized access
      final data = jsonDecode(response.body);
      throw Exception(
        data['message'],
      ); // Throw an exception for unauthorized access
    } else if (response.statusCode == 404) {
      // Handle driver not found
      final data = jsonDecode(response.body);
      throw Exception(
        data['message'],
      ); // Throw an exception for driver not found
    } else {
      // Handle other errors
      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    }
  }
}
