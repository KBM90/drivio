import 'package:drivio_app/common/constants/api.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DriverLocationProvider with ChangeNotifier {
  LatLng? _currentLocation;

  LatLng? get currentLocation => _currentLocation;

  /// Fetch user location and update state

  Future<void> updateLocation() async {
    LatLng? location = await GeolocatorHelper.getCurrentLocation();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (location != null) {
      _currentLocation = location;
      notifyListeners(); // 🔔 Notify UI about changes

      // Send location to Laravel backend
      final response = await http.post(
        Uri.parse('${Api.baseUrl}/updateLocation'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // Add if using authentication
        },
        body: jsonEncode(<String, dynamic>{
          'latitude': location.latitude,
          'longitude': location.longitude,
        }),
      );

      if (response.statusCode == 200) {
        print('Location updated successfully');
      } else {
        print('Failed to update location: ${response.body}');
      }
    }
  }
}
