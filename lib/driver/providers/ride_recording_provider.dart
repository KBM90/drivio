import 'package:camera/camera.dart';
import 'package:drivio_app/common/models/ride_recording.dart';
import 'package:drivio_app/driver/services/ride_recording_service.dart';
import 'package:flutter/foundation.dart';

enum RecordingStatus {
  idle,
  initializing,
  ready,
  recording,
  paused,
  stopping,
  error,
}

class RideRecordingProvider extends ChangeNotifier {
  final RideRecordingService _recordingService = RideRecordingService();

  RecordingStatus _status = RecordingStatus.idle;
  String? _currentRecordingId;
  String? _currentRideId;
  String? _errorMessage;
  List<RideRecording> _recordings = [];
  bool _isLoadingRecordings = false;

  // Getters
  RecordingStatus get status => _status;
  String? get currentRecordingId => _currentRecordingId;
  String? get currentRideId => _currentRideId;
  String? get errorMessage => _errorMessage;
  List<RideRecording> get recordings => _recordings;
  bool get isLoadingRecordings => _isLoadingRecordings;
  bool get isRecording => _status == RecordingStatus.recording;
  bool get isPaused => _status == RecordingStatus.paused;
  bool get isReady => _status == RecordingStatus.ready;
  int get recordingDuration => _recordingService.recordingDuration;
  CameraController? get cameraController => _recordingService.cameraController;

  /// Initialize camera
  Future<bool> initializeCamera({
    CameraLensDirection direction = CameraLensDirection.back,
  }) async {
    try {
      _status = RecordingStatus.initializing;
      _errorMessage = null;
      notifyListeners();

      final controller = await _recordingService.initializeCamera(
        direction: direction,
      );

      if (controller != null) {
        _status = RecordingStatus.ready;
        notifyListeners();
        return true;
      } else {
        _status = RecordingStatus.error;
        _errorMessage = 'Failed to initialize camera';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = RecordingStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Start recording
  Future<bool> startRecording({String? rideId}) async {
    try {
      if (_status != RecordingStatus.ready) {
        throw Exception('Camera not ready');
      }

      _currentRideId = rideId;
      _status = RecordingStatus.recording;
      notifyListeners();

      final recordingId = await _recordingService.startRecording(
        rideId: rideId,
      );

      if (recordingId != null) {
        _currentRecordingId = recordingId;
        // Start periodic updates for duration
        _startDurationUpdates();
        return true;
      } else {
        _status = RecordingStatus.ready;
        _errorMessage = 'Failed to start recording';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = RecordingStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Stop recording
  Future<RideRecording?> stopRecording() async {
    try {
      _status = RecordingStatus.stopping;
      notifyListeners();

      final recording = await _recordingService.stopRecording();

      _currentRecordingId = null;
      _currentRideId = null;
      _status = RecordingStatus.ready;
      notifyListeners();

      if (recording != null) {
        // Add to recordings list
        _recordings.insert(0, recording);
      }

      return recording;
    } catch (e) {
      _status = RecordingStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    try {
      await _recordingService.pauseRecording();
      _status = RecordingStatus.paused;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    try {
      await _recordingService.resumeRecording();
      _status = RecordingStatus.recording;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Switch camera
  Future<void> switchCamera() async {
    try {
      await _recordingService.switchCamera();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load user recordings
  Future<void> loadUserRecordings(String userId) async {
    try {
      _isLoadingRecordings = true;
      notifyListeners();

      _recordings = await _recordingService.getUserRecordings(userId);

      _isLoadingRecordings = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRecordings = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Load ride recordings
  Future<void> loadRideRecordings(String rideId) async {
    try {
      _isLoadingRecordings = true;
      notifyListeners();

      _recordings = await _recordingService.getRideRecordings(rideId);

      _isLoadingRecordings = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRecordings = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Delete recording
  Future<bool> deleteRecording(String recordingId, String filePath) async {
    try {
      final success = await _recordingService.deleteRecording(
        recordingId,
        filePath,
      );

      if (success) {
        _recordings.removeWhere((r) => r.id == recordingId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cleanup old recordings
  Future<int> cleanupOldRecordings(String userId, {int daysToKeep = 30}) async {
    try {
      final deletedCount = await _recordingService.cleanupOldRecordings(
        userId,
        daysToKeep: daysToKeep,
      );

      // Reload recordings
      await loadUserRecordings(userId);

      return deletedCount;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return 0;
    }
  }

  /// Dispose camera
  Future<void> disposeCamera() async {
    await _recordingService.disposeCamera();
    _status = RecordingStatus.idle;
    _currentRecordingId = null;
    _currentRideId = null;
    notifyListeners();
  }

  // Private helper methods
  void _startDurationUpdates() {
    // Notify listeners every second to update duration display
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_status == RecordingStatus.recording) {
        notifyListeners();
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _recordingService.disposeCamera();
    super.dispose();
  }
}
