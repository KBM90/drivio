import 'dart:convert';

import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeStatus {
  Future<String?> goOnline() async {
    // Fetch the current location
    final LatLng? currentLocation = await GeolocatorHelper.getCurrentLocation();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    if (currentLocation == null) {
      return 'Unable to fetch current location';
    }

    final response = await http.patch(
      Uri.parse('${Api.baseUrl}/toggleStatus'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            'Bearer $token', // Add this if using Sanctum token-based auth
      },
      body: jsonEncode({
        'location': <String, double>{
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        },
        'status': 'active',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('status', data['status']);

      return data['message']; // Return the success message
    } else if (response.statusCode == 403) {
      // Handle unauthorized access
      final data = jsonDecode(response.body);

      throw Exception(data['message']);
    } else if (response.statusCode == 404) {
      // Handle driver not found
      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    } else {
      // Handle other errors

      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    }
  }

  Future<String?> goOffline() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final response = await http
        .patch(
          Uri.parse('${Api.baseUrl}/toggleStatus'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization':
                'Bearer $token', // Add this if using Sanctum token-based auth
          },
          body: jsonEncode({'status': 'inactive'}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('status', data['status']);

      return data['message']; // Return the success message
    } else if (response.statusCode == 403) {
      // Handle unauthorized access
      final data = jsonDecode(response.body);
      debugPrint(data['message']);
      return data['message'];
    } else if (response.statusCode == 404) {
      // Handle driver not found
      final data = jsonDecode(response.body);
      debugPrint(data['message']);
      return data['message'];
    } else {
      // Handle other errors

      final data = jsonDecode(response.body);
      debugPrint(data['message']);
      return data['message'];
    }
  }

  Future<String?> onTrip() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final response = await http.patch(
      Uri.parse('${Api.baseUrl}/toggleStatus'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization':
            'Bearer $token', // Add this if using Sanctum token-based auth
      },
      body: jsonEncode({'status': 'on_trip'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await prefs.setString('status', data['status']);

      return data['message']; // Return the success message
    } else if (response.statusCode == 403) {
      // Handle unauthorized access
      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    } else if (response.statusCode == 404) {
      // Handle driver not found
      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    } else {
      // Handle other errors

      final data = jsonDecode(response.body);
      throw Exception(data['message']);
    }
  }
}
