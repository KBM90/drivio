import 'package:flutter/material.dart';
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

  /// Load language preference from Supabase users table
  Future<void> _loadLanguagePreference() async {
    try {
      final userId = AuthService.currentUserId;
      if (userId != null) {
        final userData =
            await Supabase.instance.client
                .from('users')
                .select('language')
                .eq('user_id', userId)
                .maybeSingle();

        final languageCode = userData?['language'] as String? ?? 'en';
        _currentLocale = Locale(languageCode);
        _isInitialized = true;
        notifyListeners();
      } else {
        _isInitialized = true;
        notifyListeners();
        debugPrint('ℹ️ No user logged in, using default language: en');
      }
    } catch (e) {
      debugPrint('❌ Error loading language preference: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set language and update in Supabase users table
  Future<bool> setLocale(String languageCode) async {
    if (!supportedLanguages.containsKey(languageCode)) {
      debugPrint('❌ Unsupported language code: $languageCode');
      return false;
    }

    if (_currentLocale.languageCode == languageCode) {
      return true; // Already set
    }

    try {
      final userId = AuthService.currentUserId;
      if (userId != null) {
        // Update in Supabase
        await Supabase.instance.client
            .from('users')
            .update({'language': languageCode})
            .eq('user_id', userId);

        // Update local state
        _currentLocale = Locale(languageCode);
        notifyListeners();
        return true;
      } else {
        debugPrint('❌ No user logged in, cannot update language');
        return false;
      }
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
