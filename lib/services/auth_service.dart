import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  Future<String?> register(
    String name,
    String email,
    String role,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await http.post(
      Uri.parse('${Api.baseUrl}/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'role': role,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      return null;
    }
  }

  Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Api.baseUrl}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setString('role', data['role']); // Store role
      await prefs.setInt(
        'current_user_id',
        data['user_id'],
      ); // Store current user id

      return data['token'];
    } else {
      return null;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token != null) {
      await http.post(
        Uri.parse('${Api.baseUrl}/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      await prefs.remove('auth_token');
      await prefs.remove('role');
    }
  }

  Future<bool> isAuthenticated() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<String?> getUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('role'); // Returns 'driver', 'passenger', or null
  }
}
