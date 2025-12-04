import 'package:audioplayers/audioplayers.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';

/// Sound Service - Manages all app sounds
/// Respects user's sound preferences from settings
class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// Available sound effects
  static const String errorSound = 'sounds/new_ride.mp3';
  static const String successSound = 'sounds/new_ride.mp3'; // Add this later
  static const String notificationSound =
      'sounds/new_ride.mp3'; // Add this later

  /// Play a sound effect
  /// Automatically checks if sound is enabled in settings
  static Future<void> playSound(String soundPath, {double volume = 1.0}) async {
    try {
      // Check if sound is enabled in settings
      final soundEnabled =
          await SharedPreferencesHelper().getValue<bool>('soundEnabled') ??
          true;

      if (!soundEnabled) {
        return; // Sound is disabled, don't play
      }

      // Play the sound from assets
      await _player.play(AssetSource(soundPath), volume: volume);
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  /// Play error sound
  static Future<void> playError({double volume = 1.5}) async {
    await playSound(errorSound, volume: volume);
  }

  /// Play success sound (add success.wav to assets/sounds/)
  static Future<void> playSuccess({double volume = 1.5}) async {
    await playSound(successSound, volume: volume);
  }

  /// Play notification sound (add notification.wav to assets/sounds/)
  static Future<void> playNotification({double volume = 1.5}) async {
    await playSound(notificationSound, volume: volume);
  }

  /// Stop currently playing sound
  static Future<void> stop() async {
    await _player.stop();
  }

  /// Dispose the audio player (call when app closes)
  static Future<void> dispose() async {
    await _player.dispose();
  }
}
