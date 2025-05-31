// ride_request_services.dart
import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/driver/models/ride_request.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RideRequestServices {
  static const String baseUrl = Api.baseUrl; // Replace with your real URL

  static Future<String> createRideRequest({
    required LatLng pickup,
    required LatLng destination,
    required int transportTypeId,
    required double price,
    required int paymentMethodId,
  }) async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      final distance = await OSRMService().getDistance(pickup, destination);
      final duration = await OSRMService().getDuration(pickup, destination);

      final response = await http.post(
        Uri.parse('$baseUrl/create-ride-request'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pickup_lat': pickup.latitude,
          'pickup_lng': pickup.longitude,
          'dropoff_lat': destination.latitude,
          'dropoff_lng': destination.longitude,
          'distance': distance,
          'price': price,
          'transport_type_id': transportTypeId,
          'payment_method_id': paymentMethodId,
          'duration': duration,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return body['message'] ?? 'Ride request created successfully.';
      } else if (response.statusCode == 409) {
        // User has an ongoing ride
        return body['message'] ?? 'You already have a ride in progress.';
      } else if (response.statusCode == 422) {
        return 'Validation failed: ${body['message'] ?? 'Please check your input.'}';
      } else {
        return 'Error: ${body['message'] ?? 'Something went wrong.'}';
      }
    } catch (e) {
      return 'An unexpected error occurred: $e';
    }
  }

  static Future<RideRequest?> fetchCurrentRideRequest() async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      final response = await http.get(
        Uri.parse('$baseUrl/get-ride-request'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return RideRequest.fromJson(body['ride_request']);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
