import 'dart:io';
import 'package:drivio_app/common/models/crash_report.dart';
import 'package:drivio_app/driver/services/crash_report_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CrashReportProvider extends ChangeNotifier {
  final CrashReportService _service = CrashReportService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form state
  CrashSeverity _severity = CrashSeverity.minor;
  String _description = '';
  bool _injuriesReported = false;
  int _vehiclesInvolved = 1;
  bool _policeNotified = false;
  final List<File> _selectedPhotos = [];
  final List<String> _emergencyContacted = [];

  // Location state
  double? _latitude;
  double? _longitude;
  String? _address;

  // Submission state
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;
  String? _errorMessage;

  // Crash reports list
  List<CrashReport> _crashReports = [];
  bool _isLoadingReports = false;

  // Getters
  CrashSeverity get severity => _severity;
  String get description => _description;
  bool get injuriesReported => _injuriesReported;
  int get vehiclesInvolved => _vehiclesInvolved;
  bool get policeNotified => _policeNotified;
  List<File> get selectedPhotos => _selectedPhotos;
  List<String> get emergencyContacted => _emergencyContacted;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get address => _address;
  bool get isSubmitting => _isSubmitting;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get errorMessage => _errorMessage;
  List<CrashReport> get crashReports => _crashReports;
  bool get isLoadingReports => _isLoadingReports;
  bool get hasLocation => _latitude != null && _longitude != null;

  // Setters
  void setSeverity(CrashSeverity severity) {
    _severity = severity;
    notifyListeners();
  }

  void setDescription(String description) {
    _description = description;
    notifyListeners();
  }

  void setInjuriesReported(bool value) {
    _injuriesReported = value;
    notifyListeners();
  }

  void setVehiclesInvolved(int count) {
    _vehiclesInvolved = count;
    notifyListeners();
  }

  void setPoliceNotified(bool value) {
    _policeNotified = value;
    notifyListeners();
  }

  /// Get current location
  Future<bool> getCurrentLocation() async {
    _isLoadingLocation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final locationData = await _service.getCurrentLocationWithAddress();

      if (locationData != null) {
        _latitude = locationData['latitude'];
        _longitude = locationData['longitude'];
        _address = locationData['address'];
        _isLoadingLocation = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to get location';
        _isLoadingLocation = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingLocation = false;
      notifyListeners();
      return false;
    }
  }

  /// Pick photos from gallery
  Future<void> pickPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        _selectedPhotos.addAll(images.map((xfile) => File(xfile.path)));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick photos: $e';
      notifyListeners();
    }
  }

  /// Take photo with camera
  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (photo != null) {
        _selectedPhotos.add(File(photo.path));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to take photo: $e';
      notifyListeners();
    }
  }

  /// Remove photo
  void removePhoto(int index) {
    if (index >= 0 && index < _selectedPhotos.length) {
      _selectedPhotos.removeAt(index);
      notifyListeners();
    }
  }

  /// Dial emergency number and track
  Future<bool> dialEmergency(String type) async {
    bool success = false;

    switch (type) {
      case '911':
        success = await _service.dial911();
        break;
      case 'police':
        success = await _service.dialPolice();
        break;
      case 'ambulance':
        success = await _service.dialAmbulance();
        break;
    }

    if (success && !_emergencyContacted.contains(type)) {
      _emergencyContacted.add(type);
      notifyListeners();
    }

    return success;
  }

  /// Submit crash report
  Future<CrashReport?> submitReport({int? rideId}) async {
    if (_latitude == null || _longitude == null) {
      _errorMessage = 'Location is required';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload photos first
      List<String> photoUrls = [];
      final crashId = DateTime.now().millisecondsSinceEpoch.toString();

      for (File photo in _selectedPhotos) {
        final url = await _service.uploadPhoto(photo, crashId);
        if (url != null) {
          photoUrls.add(url);
        }
      }

      // Submit crash report
      final report = await _service.submitCrashReport(
        severity: _severity,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address,
        description: _description.isNotEmpty ? _description : null,
        injuriesReported: _injuriesReported,
        vehiclesInvolved: _vehiclesInvolved,
        policeNotified: _policeNotified,
        photos: photoUrls,
        emergencyContacted: _emergencyContacted,
        rideId: rideId,
      );

      _isSubmitting = false;

      if (report != null) {
        // Reset form
        resetForm();
      } else {
        _errorMessage = 'Failed to submit report';
      }

      notifyListeners();
      return report;
    } catch (e) {
      _errorMessage = e.toString();
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  /// Fetch user's crash reports
  Future<void> fetchCrashReports() async {
    _isLoadingReports = true;
    notifyListeners();

    try {
      _crashReports = await _service.getUserCrashReports();
      _isLoadingReports = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  /// Delete crash report
  Future<bool> deleteCrashReport(String crashId) async {
    try {
      final success = await _service.deleteCrashReport(crashId);

      if (success) {
        _crashReports.removeWhere((report) => report.id == crashId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reset form
  void resetForm() {
    _severity = CrashSeverity.minor;
    _description = '';
    _injuriesReported = false;
    _vehiclesInvolved = 1;
    _policeNotified = false;
    _selectedPhotos.clear();
    _emergencyContacted.clear();
    _latitude = null;
    _longitude = null;
    _address = null;
    _errorMessage = null;
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _selectedPhotos.clear();
    super.dispose();
  }
}
