import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DriverService {
  static Future<Driver> getDriver() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/driver'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Driver.fromJson(data['driver']);
      } else {
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          print(errorData);
          throw Exception(
            errorData['message'] ?? 'Error ${response.statusCode}',
          );
        } catch (_) {
          throw Exception('Server responded with: ${response.body}');
        }
      }
    } on FormatException catch (e) {
      throw Exception('Invalid server response format: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch driver: $e');
    }
  }

  static Future<bool> updateDriverLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.patch(
        Uri.parse('${Api.baseUrl}/updateLocation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating driver location: $e');
    }
  }

  static Future<bool> updateDriverDropOffLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.patch(
        Uri.parse('${Api.baseUrl}/updateDropOffLocation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating driver location: $e');
    }
  }

  static Future<String?> acceptRideRequest(
    int rideId,
    double latitude,
    double longitude,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.patch(
        Uri.parse('${Api.baseUrl}/acceptRide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'rideId': rideId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'];
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
    } catch (e) {
      throw Exception('Error updating driver location: $e');
    }
  }

  static Future<String?> cancelTrip(String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final int? rideId = prefs.getInt('rideId');

      final response = await http.patch(
        Uri.parse('${Api.baseUrl}/cancelTrip'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason, 'ride_request_id': rideId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'];
      } else if (response.statusCode == 403) {
        // Handle unauthorized access
        final data = jsonDecode(response.body);
        throw Exception(data['message']);
      } else if (response.statusCode == 404) {
        // Handle Ride not found or driver not found
        final data = jsonDecode(response.body);
        throw Exception(data['message']);
      } else if (response.statusCode == 422) {
        // Handle insertion validation error
        final data = jsonDecode(response.body);
        throw Exception(data['message']);
      } else {
        // Handle other errors

        final data = jsonDecode(response.body);
        throw Exception(data['message']);
      }
    } catch (e) {
      throw Exception('Error updating driver location: $e');
    }
  }
}
