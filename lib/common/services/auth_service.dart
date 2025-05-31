import 'dart:async';
import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/common/models/user.dart';
import 'package:drivio_app/driver/services/change_status.dart';
import 'package:drivio_app/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

        // Parse the user model
        final user = User.fromJson(data['user']);

        // Store authentication token
        await SharedPreferencesHelper.clearAll();
        await SharedPreferencesHelper().setString(
          'auth_token',
          data['auth_token'],
        );

        // Store user role

        await SharedPreferencesHelper().setString('role', data['role']);

        // Store complete user model as JSON

        await SharedPreferencesHelper().setString(
          "current_user",
          jsonEncode(user.toJson()),
        );

        return user;
      } else {
        //  final errorData = jsonDecode(response.body);
        return null;
      }
    } catch (e) {
      return null;
      // throw Exception('Login error: $e');
    }
  }

  Future<void> logout() async {
    try {
      // 1. Get the auth token
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );

      // 2. Make API call if token exists
      if (token != null) {
        await ChangeStatus().goOffline();
        final response = await http
            .post(
              Uri.parse('${Api.baseUrl}/logout'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        // Handle different response statuses
        if (response.statusCode != 200) {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Logout failed');
        }
      }

      // 3. Clear all local data (using SharedPreferencesHelper)

      await SharedPreferencesHelper.clearAll();

      // 4. Optional: Clear any other app state
      // Example: Provider.of<AuthProvider>(context, listen: false).clearAuthState();

      // 5. Navigate to login screen
      Navigator.of(
        navigatorKey.currentContext!,
      ).pushNamedAndRemoveUntil('/login', (route) => false);
    } on TimeoutException {
      // Handle timeout specifically
      debugPrint('Logout timeout');
      // Still proceed with local cleanup even if API fails
      await SharedPreferencesHelper.clearAll();

      _showLogoutMessage('Connection timeout, but local data was cleared');
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still proceed with local cleanup even if API fails
      await SharedPreferencesHelper.clearAll();

      _showLogoutMessage('Logged out locally (${e.toString()})');
    }
  }

  void _showLogoutMessage(String message) {
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(
        navigatorKey.currentContext!,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
