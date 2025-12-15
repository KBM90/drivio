import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:drivio_app/common/models/ride_recording.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class RideRecordingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Recording state
  CameraController? _cameraController;
  String? _currentRecordingId;
  DateTime? _recordingStartTime;
  Timer? _durationTimer;
  int _recordingDuration = 0;

  // Getters
  bool get isRecording => _cameraController?.value.isRecordingVideo ?? false;
  bool get isRecordingPaused =>
      _cameraController?.value.isRecordingPaused ?? false;
  int get recordingDuration => _recordingDuration;
  CameraController? get cameraController => _cameraController;

  /// Initialize camera for recording
  Future<CameraController?> initializeCamera({
    CameraLensDirection direction = CameraLensDirection.back,
  }) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == direction,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      return _cameraController;
    } catch (e) {
      print('Error initializing camera: $e');
      return null;
    }
  }

  /// Start recording a ride
  Future<String?> startRecording({String? rideId}) async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw Exception('Camera not initialized');
      }

      if (isRecording) {
        throw Exception('Already recording');
      }

      // Generate recording ID
      _currentRecordingId = _uuid.v4();
      _recordingStartTime = DateTime.now();
      _recordingDuration = 0;

      // Start video recording
      await _cameraController!.startVideoRecording();

      // Start duration timer
      _startDurationTimer();

      // Create database entry
      await _createRecordingEntry(rideId);

      return _currentRecordingId;
    } catch (e) {
      print('Error starting recording: $e');
      _currentRecordingId = null;
      _recordingStartTime = null;
      return null;
    }
  }

  /// Stop recording
  Future<RideRecording?> stopRecording() async {
    try {
      if (_cameraController == null || !isRecording) {
        throw Exception('Not currently recording');
      }

      // Stop duration timer
      _durationTimer?.cancel();

      // Stop video recording
      final XFile videoFile = await _cameraController!.stopVideoRecording();

      // Move file to permanent storage
      final savedPath = await _saveRecordingFile(videoFile);

      // Get file size
      final file = File(savedPath);
      final fileSize = await file.length();

      // Update database entry
      final recording = await _updateRecordingEntry(
        savedPath,
        fileSize,
        _recordingDuration,
      );

      // Reset state
      _currentRecordingId = null;
      _recordingStartTime = null;
      _recordingDuration = 0;

      return recording;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    try {
      if (_cameraController == null || !isRecording || isRecordingPaused) {
        return;
      }

      await _cameraController!.pauseVideoRecording();
      _durationTimer?.cancel();
    } catch (e) {
      print('Error pausing recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    try {
      if (_cameraController == null || !isRecording || !isRecordingPaused) {
        return;
      }

      await _cameraController!.resumeVideoRecording();
      _startDurationTimer();
    } catch (e) {
      print('Error resuming recording: $e');
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    try {
      if (_cameraController == null) return;

      final currentDirection = _cameraController!.description.lensDirection;
      final newDirection =
          currentDirection == CameraLensDirection.back
              ? CameraLensDirection.front
              : CameraLensDirection.back;

      await disposeCamera();
      await initializeCamera(direction: newDirection);
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  /// Dispose camera controller
  Future<void> disposeCamera() async {
    _durationTimer?.cancel();
    await _cameraController?.dispose();
    _cameraController = null;
  }

  /// Get all recordings for a user
  Future<List<RideRecording>> getUserRecordings(String userId) async {
    try {
      final response = await _supabase
          .from('ride_recordings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RideRecording.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching recordings: $e');
      return [];
    }
  }

  /// Get recordings for a specific ride
  Future<List<RideRecording>> getRideRecordings(String rideId) async {
    try {
      final response = await _supabase
          .from('ride_recordings')
          .select()
          .eq('ride_id', rideId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => RideRecording.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching ride recordings: $e');
      return [];
    }
  }

  /// Delete a recording
  Future<bool> deleteRecording(String recordingId, String filePath) async {
    try {
      // Delete file
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Delete database entry
      await _supabase.from('ride_recordings').delete().eq('id', recordingId);

      return true;
    } catch (e) {
      print('Error deleting recording: $e');
      return false;
    }
  }

  /// Clean up old recordings (older than specified days)
  Future<int> cleanupOldRecordings(String userId, {int daysToKeep = 30}) async {
    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: daysToKeep)).toIso8601String();

      final response = await _supabase
          .from('ride_recordings')
          .select()
          .eq('user_id', userId)
          .lt('created_at', cutoffDate);

      final recordings =
          (response as List)
              .map((json) => RideRecording.fromJson(json))
              .toList();

      int deletedCount = 0;
      for (final recording in recordings) {
        final success = await deleteRecording(recording.id, recording.filePath);
        if (success) deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      print('Error cleaning up recordings: $e');
      return 0;
    }
  }

  // Private helper methods

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingDuration++;
    });
  }

  Future<void> _createRecordingEntry(String? rideId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('ride_recordings').insert({
        'id': _currentRecordingId,
        'ride_id': rideId,
        'user_id': userId,
        'file_path': '', // Will be updated when recording stops
        'start_time': _recordingStartTime!.toIso8601String(),
        'is_uploaded': false,
      });
    } catch (e) {
      print('Error creating recording entry: $e');
      rethrow;
    }
  }

  Future<RideRecording?> _updateRecordingEntry(
    String filePath,
    int fileSize,
    int duration,
  ) async {
    try {
      final response =
          await _supabase
              .from('ride_recordings')
              .update({
                'file_path': filePath,
                'file_size': fileSize,
                'duration': duration,
                'end_time': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', _currentRecordingId!)
              .select()
              .single();

      return RideRecording.fromJson(response);
    } catch (e) {
      print('Error updating recording entry: $e');
      return null;
    }
  }

  Future<String> _saveRecordingFile(XFile videoFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/ride_recordings');

      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final fileName =
          'recording_${_currentRecordingId}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final savedPath = '${recordingsDir.path}/$fileName';

      await File(videoFile.path).copy(savedPath);

      return savedPath;
    } catch (e) {
      print('Error saving recording file: $e');
      rethrow;
    }
  }
}
