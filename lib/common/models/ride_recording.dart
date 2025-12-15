import 'package:json_annotation/json_annotation.dart';

part 'ride_recording.g.dart';

@JsonSerializable()
class RideRecording {
  final String id;
  final String? rideId;
  final String userId;
  final String filePath;
  final int? fileSize; // in bytes
  final int? duration; // in seconds
  final DateTime startTime;
  final DateTime? endTime;
  final bool isUploaded;
  final DateTime createdAt;
  final DateTime updatedAt;

  RideRecording({
    required this.id,
    this.rideId,
    required this.userId,
    required this.filePath,
    this.fileSize,
    this.duration,
    required this.startTime,
    this.endTime,
    this.isUploaded = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RideRecording.fromJson(Map<String, dynamic> json) =>
      _$RideRecordingFromJson(json);

  Map<String, dynamic> toJson() => _$RideRecordingToJson(this);

  RideRecording copyWith({
    String? id,
    String? rideId,
    String? userId,
    String? filePath,
    int? fileSize,
    int? duration,
    DateTime? startTime,
    DateTime? endTime,
    bool? isUploaded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RideRecording(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      userId: userId ?? this.userId,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isUploaded: isUploaded ?? this.isUploaded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedDuration {
    if (duration == null) return '00:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Unknown';
    final mb = fileSize! / (1024 * 1024);
    if (mb < 1) {
      final kb = fileSize! / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }
}
