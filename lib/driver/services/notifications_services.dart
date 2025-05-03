import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsServices {
  Future<Map<String, dynamic>> createNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse("${Api.baseUrl}/create-notification"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'type': type,
          'title': title,
          'message': message,
          'data': data,
        }),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': jsonDecode(response.body)['message'],
          'notification': jsonDecode(response.body)['notification'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create notification',
          'error': jsonDecode(response.body)['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Exception occurred while creating notification',
        'error': e.toString(),
      };
    }
  }
}
