import 'package:flutter/material.dart';
import 'package:drivio_app/common/constants/app_theme.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';

/// Theme Provider to manage app theme state
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isInitialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;

  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    try {
      final isDark =
          await SharedPreferencesHelper().getValue<bool>('isDarkMode') ?? false;
      _isDarkMode = isDark;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading theme preference: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();

    try {
      await SharedPreferencesHelper.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      debugPrint('❌ Error saving theme preference: $e');
    }
  }

  /// Set theme explicitly
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;

    _isDarkMode = isDark;
    notifyListeners();

    try {
      await SharedPreferencesHelper.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      debugPrint('❌ Error saving theme preference: $e');
    }
  }
}
