import 'dart:convert';
import 'package:drivio_app/common/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static Future<User?> getPersistanceCurrentUser() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('current_user');

      if (userJson == null) return null;

      final Map<String, dynamic> userMap = jsonDecode(userJson);
      return User.fromJson(userMap);
    } catch (e) {
      print('Error retrieving user: $e');
      return null;
    }
  }

  static Future<void> clearUser() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('current_user'),
        prefs.remove('auth_token'),
        prefs.remove('role'),
        prefs.remove('current_user_id'),
      ]);
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  static Future<void> saveUser(User user) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user', jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving user: $e');
    }
  }
}
