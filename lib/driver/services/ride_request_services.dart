import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/ride_request.dart';

class RideRequestService {
  /// Fetch ride requests within 10km from driver's location & matching preferences
  static Future<List<RideRequest>> getRideRequests(
    LatLng driverLocation,
  ) async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }
      // Driver driver = await DriverService.getDriver();

      /*  if (driver.location == null) {
        throw Exception("Driver location is missing.");
      }*/

      // ✅ Construct the URL with query parameters
      final Uri url = Uri.parse('${Api.baseUrl}/getRideRequests').replace(
        queryParameters: {
          'latitude': driverLocation.latitude.toString(),
          'longitude': driverLocation.longitude.toString(),
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
      }
      if (response.statusCode == 500) {
        //handling no ride request found
        // ✅ Convert list items to RideRequest objects
        print(response.body);
        return [];
      } else {
        throw Exception(
          "Failed to fetch ride requests: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching ride requests: $e");
    }
  }

  ///Fetch the choosen ride request
  static Future<RideRequest> getRideRequest(int id) async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );

      if (token == null) {
        throw Exception("Authentication token is missing.");
      }

      // ✅ Construct the URL with query parameters
      final Uri url = Uri.parse(
        '${Api.baseUrl}/getRideRequestById',
      ).replace(queryParameters: {'id': id.toString()});

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
        RideRequest rideRequest = RideRequest.fromJson(
          data as Map<String, dynamic>,
        );
        return rideRequest;
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
