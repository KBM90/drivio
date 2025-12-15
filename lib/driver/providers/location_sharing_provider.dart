import 'package:drivio_app/driver/services/location_sharing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedContact {
  final String name;
  final String phoneNumber;
  final DateTime sharedAt;

  SharedContact({
    required this.name,
    required this.phoneNumber,
    required this.sharedAt,
  });
}

class LocationSharingProvider extends ChangeNotifier {
  final LocationSharingService _service = LocationSharingService();

  bool _isSharing = false;
  final List<SharedContact> _sharedContacts = [];
  Position? _currentPosition;
  String? _errorMessage;
  String? _currentRideId;
  String? _driverName;

  // Getters
  bool get isSharing => _isSharing;
  List<SharedContact> get sharedContacts => _sharedContacts;
  Position? get currentPosition => _currentPosition;
  String? get errorMessage => _errorMessage;
  int get sharedContactsCount => _sharedContacts.length;

  /// Initialize location sharing for a ride
  Future<void> initializeSharing({String? rideId, String? driverName}) async {
    _currentRideId = rideId;
    _driverName = driverName;
    await updateCurrentLocation();
  }

  /// Update current location
  Future<bool> updateCurrentLocation() async {
    try {
      _currentPosition = await _service.getCurrentLocation();
      if (_currentPosition == null) {
        _errorMessage = 'Failed to get current location';
        notifyListeners();
        return false;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Generate sharing message with current location
  String? generateMessage() {
    if (_currentPosition == null) return null;

    return _service.generateSharingMessage(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      rideId: _currentRideId,
      driverName: _driverName,
    );
  }

  /// Share location via WhatsApp
  Future<bool> shareViaWhatsApp(String name, String phoneNumber) async {
    try {
      // Update location before sharing
      await updateCurrentLocation();

      if (_currentPosition == null) {
        _errorMessage = 'Location not available';
        notifyListeners();
        return false;
      }

      final message = generateMessage();
      if (message == null) {
        _errorMessage = 'Failed to generate message';
        notifyListeners();
        return false;
      }

      // Format phone number
      final formattedNumber = _service.formatPhoneNumber(phoneNumber);

      // Share via WhatsApp
      final success = await _service.shareViaWhatsApp(
        phoneNumber: formattedNumber,
        message: message,
      );

      if (success) {
        _addSharedContact(name, phoneNumber);
        _isSharing = true;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to share via WhatsApp';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Share location via SMS
  Future<bool> shareViaSMS(String name, String phoneNumber) async {
    try {
      await updateCurrentLocation();

      if (_currentPosition == null) {
        _errorMessage = 'Location not available';
        notifyListeners();
        return false;
      }

      final message = generateMessage();
      if (message == null) {
        _errorMessage = 'Failed to generate message';
        notifyListeners();
        return false;
      }

      final success = await _service.shareViaSMS(
        phoneNumber: phoneNumber,
        message: message,
      );

      if (success) {
        _addSharedContact(name, phoneNumber);
        _isSharing = true;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to share via SMS';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Share location via other apps (share sheet)
  Future<bool> shareViaOtherApps() async {
    try {
      await updateCurrentLocation();

      if (_currentPosition == null) {
        _errorMessage = 'Location not available';
        notifyListeners();
        return false;
      }

      final message = generateMessage();
      if (message == null) {
        _errorMessage = 'Failed to generate message';
        notifyListeners();
        return false;
      }

      // Use share_plus to show share sheet
      await Share.share(message);

      _isSharing = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Share location via WhatsApp (direct - no phone number needed)
  Future<bool> shareViaWhatsAppDirect() async {
    try {
      await updateCurrentLocation();

      if (_currentPosition == null) {
        _errorMessage = 'Location not available';
        notifyListeners();
        return false;
      }

      final message = generateMessage();
      if (message == null) {
        _errorMessage = 'Failed to generate message';
        notifyListeners();
        return false;
      }

      // Encode the message for URL
      final encodedMessage = Uri.encodeComponent(message);

      // WhatsApp URL without phone number - will show contact picker
      final whatsappUrl = Uri.parse('https://wa.me/?text=$encodedMessage');

      if (await canLaunchUrl(whatsappUrl)) {
        final success = await launchUrl(
          whatsappUrl,
          mode: LaunchMode.externalApplication,
        );

        if (success) {
          _isSharing = true;
          _errorMessage = null;
        } else {
          _errorMessage = 'Failed to open WhatsApp';
        }

        notifyListeners();
        return success;
      } else {
        _errorMessage = 'WhatsApp not installed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Share location via SMS (direct - no phone number needed)
  Future<bool> shareViaSMSDirect() async {
    try {
      await updateCurrentLocation();

      if (_currentPosition == null) {
        _errorMessage = 'Location not available';
        notifyListeners();
        return false;
      }

      final message = generateMessage();
      if (message == null) {
        _errorMessage = 'Failed to generate message';
        notifyListeners();
        return false;
      }

      // SMS URL without phone number - will show contact picker
      final smsUrl = Uri.parse('sms:?body=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(smsUrl)) {
        final success = await launchUrl(smsUrl);

        if (success) {
          _isSharing = true;
          _errorMessage = null;
        } else {
          _errorMessage = 'Failed to open SMS';
        }

        notifyListeners();
        return success;
      } else {
        _errorMessage = 'SMS not available';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Stop sharing location
  void stopSharing() {
    _isSharing = false;
    _sharedContacts.clear();
    _currentRideId = null;
    _driverName = null;
    notifyListeners();
  }

  /// Add a contact to shared list
  void _addSharedContact(String name, String phoneNumber) {
    final contact = SharedContact(
      name: name,
      phoneNumber: phoneNumber,
      sharedAt: DateTime.now(),
    );

    // Check if contact already exists
    final existingIndex = _sharedContacts.indexWhere(
      (c) => c.phoneNumber == phoneNumber,
    );

    if (existingIndex >= 0) {
      // Update existing contact
      _sharedContacts[existingIndex] = contact;
    } else {
      // Add new contact
      _sharedContacts.add(contact);
    }
  }

  /// Remove a contact from shared list
  void removeSharedContact(String phoneNumber) {
    _sharedContacts.removeWhere((c) => c.phoneNumber == phoneNumber);

    if (_sharedContacts.isEmpty) {
      _isSharing = false;
    }

    notifyListeners();
  }

  /// Validate phone number
  bool validatePhoneNumber(String phoneNumber) {
    return _service.isValidPhoneNumber(phoneNumber);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sharedContacts.clear();
    super.dispose();
  }
}
