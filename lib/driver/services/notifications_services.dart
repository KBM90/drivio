import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:http/http.dart' as http;

class NotificationsServices {
  Future<Map<String, dynamic>> createNotification({
    required userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse("${Api.baseUrl}/create-notification"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
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
