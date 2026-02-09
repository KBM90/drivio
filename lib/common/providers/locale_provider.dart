import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Locale Provider to manage app language state
class LocaleProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  bool _isInitialized = false;

  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
    'es': 'Español',
    'de': 'Deutsch',
  };

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('fr'),
    Locale('ar'),
    Locale('es'),
    Locale('de'),
  ];

  LocaleProvider() {
    _loadLanguagePreference();
  }

  /// Load language preference from SharedPreferences and then Supabase
  Future<void> _loadLanguagePreference() async {
    try {
      // 1. Load from SharedPreferences first (fastest)
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language_code');

      if (savedLanguage != null &&
          supportedLanguages.containsKey(savedLanguage)) {
        _currentLocale = Locale(savedLanguage);
        notifyListeners();
      }

      // 2. If logged in, sync with Supabase
      final userId = AuthService.currentUserId;
      if (userId != null) {
        final userData =
            await Supabase.instance.client
                .from('users')
                .select('language')
                .eq('user_id', userId)
                .maybeSingle();

        if (userData != null) {
          final languageCode = userData['language'] as String? ?? 'en';

          // If Supabase has a different language, update local state
          if (languageCode != _currentLocale.languageCode) {
            _currentLocale = Locale(languageCode);
            // Also update SharedPreferences to keep them in sync
            await prefs.setString('language_code', languageCode);
            notifyListeners();
          }
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading language preference: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set language and update in SharedPreferences and Supabase
  Future<bool> setLocale(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      debugPrint('❌ Unsupported language code: $languageCode');
      return false;
    }

    if (_currentLocale.languageCode == languageCode) {
      return true; // Already set
    }

    try {
      // 1. Update local state immediatey
      _currentLocale = Locale(languageCode);
      notifyListeners();

      // 2. Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);

      // 3. If logged in, update Supabase
      final userId = AuthService.currentUserId;
      if (userId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'language': languageCode})
            .eq('user_id', userId);
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error updating language: $e');
      return false;
    }
  }

  /// Check if current language is RTL (Right-to-Left)
  bool get isRTL => _currentLocale.languageCode == 'ar';

  /// Get language name for current locale
  String get currentLanguageName =>
      supportedLanguages[_currentLocale.languageCode] ?? 'English';
}
