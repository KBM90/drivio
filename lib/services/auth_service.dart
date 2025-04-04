import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/models/user.dart';
import 'package:drivio_app/common/services/user_services.dart';
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

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      return null;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        // Parse the user model
        final user = User.fromJson(data['user']);

        // Store authentication token
        await prefs.setString('auth_token', data['auth_token']);
        // Store user role
        await prefs.setString('role', data['role']);
        // Store complete user model as JSON
        await prefs.setString('current_user', jsonEncode(user.toJson()));

        return user;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
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

      await UserService.clearUser();
    }
  }

  Future<bool> isAuthenticated() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  Future<void> getUser(String token) async {
    var response = await http.get(
      Uri.parse('${Api.baseUrl}/user'),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
