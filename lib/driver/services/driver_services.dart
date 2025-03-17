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

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/driver'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['driver'] == null) {
          throw Exception('Driver data not found in response');
        }

        return Driver.fromJson(data['driver']);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching driver: $e');
    }
  }
}
