import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  // Private constructor
  SharedPreferencesHelper._();

  // Singleton instance
  static final SharedPreferencesHelper _instance = SharedPreferencesHelper._();

  // Factory constructor to provide the same instance
  factory SharedPreferencesHelper() => _instance;

  // Clear all stored preferences
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing shared preferences: $e');
      return false;
    }
  }

  // Alternative: Clear all except certain keys
  static Future<bool> clearAllExcept(List<String> keysToKeep) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      for (String key in allKeys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
        }
      }
      return true;
    } catch (e) {
      print('Error clearing shared preferences: $e');
      return false;
    }
  }

  static Future<bool> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(key);
  }

  static Future<bool> containsKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }

  /// Generic method to get a value from SharedPreferences
  ///
  /// Example usage:
  /// String? name = await SharedPreferencesHelper().getValue<String>('username');
  /// int? age = await SharedPreferencesHelper().getValue<int>('user_age');
  /// bool? isDarkMode = await SharedPreferencesHelper().getValue<bool>('dark_mode');
  Future<T?> getValue<T>(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (T == String) {
        return prefs.getString(key) as T?;
      } else if (T == int) {
        return prefs.getInt(key) as T?;
      } else if (T == bool) {
        return prefs.getBool(key) as T?;
      } else if (T == double) {
        return prefs.getDouble(key) as T?;
      } else if (T == List<String>) {
        return prefs.getStringList(key) as T?;
      } else {
        throw ArgumentError('Type $T not supported');
      }
    } catch (e) {
      print('Error getting preference $key: $e');
      return null;
    }
  }

  /// Type-specific convenience methods

  Future<String?> getString(String key) async => getValue<String>(key);
  Future<int?> getInt(String key) async => getValue<int>(key);
  Future<bool?> getBool(String key) async => getValue<bool>(key);
  Future<double?> getDouble(String key) async => getValue<double>(key);
  Future<List<String>?> getStringList(String key) async =>
      getValue<List<String>>(key);

  /// Set a String value
  static Future<bool> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(key, value);
  }

  /// Set an int value
  Future<bool> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(key, value);
  }

  /// Set a bool value
  Future<bool> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(key, value);
  }

  /// Set a double value
  Future<bool> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setDouble(key, value);
  }

  /// Set a List<String> value
  Future<bool> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setStringList(key, value);
  }
}
