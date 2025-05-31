import 'dart:async';
import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:http/http.dart' as http;

class DriverService {
  static Future<Driver> getDriver() async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );

      // More detailed token validation
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found or empty');
      }

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/driver'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Handle specific status codes
      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          return Driver.fromJson(data['driver']);
        case 401:
          // Clear invalid token and trigger re-authentication
          await SharedPreferencesHelper.clearAll();

          throw Exception('Session expired. Please login again.');
        case 403:
          throw Exception('Forbidden: You don\'t have permission');
        default:
          throw Exception(
            'Server error: ${response.statusCode} - ${response.body}',
          );
      }
    } on FormatException catch (e) {
      throw Exception('Invalid server response format: ${e.message}');
    } on TimeoutException {
      throw Exception('Request timed out. Please check your connection');
    } catch (e) {
      throw Exception('Failed to fetch driver: $e');
    }
  }

  static Future<bool> updateDriverLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }

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
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }

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
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }

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
        SharedPreferencesHelper().setInt("currentRideId", rideId);
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
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final int? rideId = await SharedPreferencesHelper().getInt(
        "currentRideId",
      );

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

  static Future<String> stopNewRequsts() async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.patch(
        Uri.parse('${Api.baseUrl}/stopNewRequests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      throw Exception('Error updating driver availability: $e');
    }
  }

  static Future<String> acceptNewRequests() async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.patch(
        Uri.parse('${Api.baseUrl}/acceptNewRequests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      throw Exception('Error updating driver availability: $e');
    }
  }
}
