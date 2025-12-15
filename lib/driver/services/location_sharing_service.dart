import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationSharingService {
  /// Generate a Google Maps link with current location
  String generateLocationLink(double latitude, double longitude) {
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  /// Generate a formatted message for sharing
  String generateSharingMessage({
    required double latitude,
    required double longitude,
    String? rideId,
    String? driverName,
  }) {
    final locationLink = generateLocationLink(latitude, longitude);
    final startTime = DateFormat('HH:mm').format(DateTime.now());

    return '''
🚗 I'm on a ride with Drivio!

📍 Track my location:
$locationLink

🕐 Started: $startTime
${rideId != null ? '🎫 Ride ID: ${rideId.substring(0, 8)}' : ''}
${driverName != null ? '👤 Driver: $driverName' : ''}

📱 Tap the link to see my current location

Stay safe! 💙
''';
  }

  /// Share location via WhatsApp
  Future<bool> shareViaWhatsApp({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Remove any non-digit characters from phone number
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Encode the message for URL
      final encodedMessage = Uri.encodeComponent(message);

      // WhatsApp URL scheme
      final whatsappUrl = Uri.parse(
        'https://wa.me/$cleanNumber?text=$encodedMessage',
      );

      if (await canLaunchUrl(whatsappUrl)) {
        return await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch WhatsApp');
      }
    } catch (e) {
      print('Error sharing via WhatsApp: $e');
      return false;
    }
  }

  /// Share location via SMS
  Future<bool> shareViaSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final smsUrl = Uri.parse(
        'sms:$phoneNumber?body=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(smsUrl)) {
        return await launchUrl(smsUrl);
      } else {
        throw Exception('Could not launch SMS');
      }
    } catch (e) {
      print('Error sharing via SMS: $e');
      return false;
    }
  }

  /// Share location via any app (using share sheet)
  Future<bool> shareViaOtherApps({required String message}) async {
    try {
      // This will be handled by share_plus package in the provider
      return true;
    } catch (e) {
      print('Error sharing: $e');
      return false;
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Format phone number for WhatsApp (add country code if missing)
  String formatPhoneNumber(
    String phoneNumber, {
    String defaultCountryCode = '1',
  }) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If number doesn't start with +, add default country code
    if (!cleaned.startsWith('+')) {
      cleaned = '+$defaultCountryCode$cleaned';
    }

    return cleaned;
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }
}
