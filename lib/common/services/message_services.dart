import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MessageService {
  final String baseUrl = Api.baseUrl;

  MessageService();

  // Fetch messages between the driver and a passenger
  Future<List<Map<String, dynamic>>> fetchMessages(int receiverId) async {
    final prefs = await SharedPreferences.getInstance();

    final String? apiToken = prefs.getString('auth_token');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/messages/$receiverId'),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = jsonDecode(response.body);
        print(messagesJson.map((msg) => msg as Map<String, dynamic>).toList());
        return messagesJson.map((msg) => msg as Map<String, dynamic>).toList();
      } else {
        print('Failed to fetch messages: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  // Send a message to a passenger
  Future<bool> sendMessage(int receiverId, String message) async {
    final prefs = await SharedPreferences.getInstance();

    final String? apiToken = prefs.getString('auth_token');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'receiver_id': receiverId, 'message': message}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Failed to send message: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
}
