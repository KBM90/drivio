import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/driver/models/driver_preferences.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverPreferencesService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Load driver preferences from database
  Future<DriverPreferences?> loadPreferences() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        debugPrint('❌ No driver ID found');
        return null;
      }

      final response =
          await _supabase
              .from('drivers')
              .select('preferences')
              .eq('id', driverId)
              .maybeSingle();

      if (response == null || response['preferences'] == null) {
        debugPrint('ℹ️ No preferences found, returning defaults');
        return const DriverPreferences();
      }

      final prefsJson = response['preferences'] as Map<String, dynamic>;
      return DriverPreferences.fromJson(prefsJson);
    } catch (e) {
      debugPrint('❌ Error loading preferences: $e');
      return const DriverPreferences();
    }
  }

  /// Load driver range from database
  Future<double> loadRange() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        debugPrint('❌ No driver ID found');
        return 10.0; // Default
      }

      final response =
          await _supabase
              .from('drivers')
              .select('range')
              .eq('id', driverId)
              .maybeSingle();

      if (response == null || response['range'] == null) {
        return 10.0; // Default
      }

      return (response['range'] as num).toDouble();
    } catch (e) {
      debugPrint('❌ Error loading range: $e');
      return 10.0; // Default
    }
  }

  /// Save driver preferences and optionally range to database
  Future<bool> savePreferences(
    DriverPreferences preferences, {
    double? range,
  }) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        debugPrint('❌ No driver ID found');
        return false;
      }

      final updateData = <String, dynamic>{'preferences': preferences.toJson()};

      // Add range to update if provided
      if (range != null) {
        updateData['range'] = range;
      }

      await _supabase.from('drivers').update(updateData).eq('id', driverId);

      debugPrint(
        '✅ Preferences${range != null ? ' and range' : ''} saved successfully',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error saving preferences: $e');
      return false;
    }
  }

  /// Reset preferences and range to defaults
  Future<bool> resetPreferences() async {
    return await savePreferences(const DriverPreferences(), range: 10.0);
  }
}
