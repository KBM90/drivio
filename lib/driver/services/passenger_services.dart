import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/passenger/models/passenger.dart';
import 'package:http/http.dart' as http;

class PassengerService {
  static Future<Passenger> getPassenger(int passengerId) async {
    final token = await SharedPreferencesHelper().getValue<String>(
      'auth_token',
    );
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse(
        '${Api.baseUrl}/passenger?passengerId=$passengerId',
      ), // Use route parameter
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Extract the 'data' field from the response
      if (data['data'] != null) {
        return Passenger.fromJson(data['data']);
      } else {
        throw Exception('Passenger data not found in response');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Error fetching passenger');
    }
  }
}
