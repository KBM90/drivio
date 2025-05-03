import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/models/map_report.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapReportService {
  // Base URL of your Laravel API (replace with your actual URL)
  static const String _baseUrl = Api.baseUrl;

  // Function to submit a map report
  static Future<bool> submitReport({
    required String reportType,
    LatLng? point, // Single point
    List<LatLng>? path, // Route points
    String? description,
    // Bearer token for authentication
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('$_baseUrl/create-map-report');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Prepare the request body
    final body = jsonEncode({
      'report_type': reportType,
      if (point != null) ...{
        'point_latitude': point.latitude,
        'point_longitude': point.longitude,
      },

      if (path != null && path.isNotEmpty) ...{
        'path': path.map((p) => [p.latitude, p.longitude]).toList(),
      },
      'description': description ?? 'Reported via map', // Default if null
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        return true; // Success
      } else {
        debugPrint('Failed to submit report: ${response.body}');
        return false; // Failure
      }
    } catch (e) {
      debugPrint('Error submitting report: $e');
      return false; // Error
    }
  }

  static Future<List<MapReport>> getReportsWithinRadius() async {
    final prefs = await SharedPreferences.getInstance();
    final LatLng? driverLocation = await GeolocatorHelper.getCurrentLocation();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('$_baseUrl/get-map-reports');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'latitude': driverLocation!.latitude,
          'longitude': driverLocation.longitude,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          final List<dynamic> reportsJson = responseData['data'];
          print(responseData['data']);
          return reportsJson.map((json) => MapReport.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch reports');
        }
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getReportsWithinRadius: $e');
      rethrow;
    }
  }

  static Future<List<MapReport>> getUserMapReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final url = Uri.parse('$_baseUrl/get-user-reports');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          final List<dynamic> reportsJson = responseData['data'];
          return reportsJson.map((json) => MapReport.fromJson(json)).toList();
        } else {
          throw Exception(responseData['message'] ?? 'Failed to fetch reports');
        }
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getReportsWithinRadius: $e');
      rethrow;
    }
  }
}
