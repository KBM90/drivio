import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/driver_services.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/models/ride_request.dart';

class RideRequestService {
  /// Fetch ride requests within 10km from driver's location & matching preferences
  static Future<List<RideRequest>> getRideRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      Driver driver = await DriverService.getDriver();

      if (token == null) {
        throw Exception("Authentication token is missing.");
      }

      if (driver.location == null) {
        throw Exception("Driver location is missing.");
      }

      // ✅ Construct the URL with query parameters
      final Uri url = Uri.parse('${Api.baseUrl}/getRideRequests').replace(
        queryParameters: {
          'latitude': driver.location!.latitude.toString(),
          'longitude': driver.location!.longitude.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        dynamic data = jsonDecode(response.body);
        // ✅ Extract ride_requests list
        final List<dynamic> rideRequestsList = data['ride_requests'] ?? [];

        // ✅ Convert list items to RideRequest objects
        return rideRequestsList
            .map((json) => RideRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          "Failed to fetch ride requests: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching ride requests: $e");
    }
  }
}
