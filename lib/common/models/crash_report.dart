import 'package:json_annotation/json_annotation.dart';

part 'crash_report.g.dart';

enum CrashSeverity {
  @JsonValue('minor')
  minor,
  @JsonValue('moderate')
  moderate,
  @JsonValue('severe')
  severe,
}

@JsonSerializable()
class CrashReport {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'ride_id')
  final int? rideId;
  final CrashSeverity severity;
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;
  @JsonKey(name: 'injuries_reported')
  final bool injuriesReported;
  @JsonKey(name: 'vehicles_involved')
  final int vehiclesInvolved;
  @JsonKey(name: 'police_notified')
  final bool policeNotified;
  final List<String> photos;
  @JsonKey(name: 'emergency_contacted')
  final List<String> emergencyContacted;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CrashReport({
    required this.id,
    required this.userId,
    this.rideId,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
    this.injuriesReported = false,
    this.vehiclesInvolved = 1,
    this.policeNotified = false,
    this.photos = const [],
    this.emergencyContacted = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory CrashReport.fromJson(Map<String, dynamic> json) =>
      _$CrashReportFromJson(json);

  Map<String, dynamic> toJson() => _$CrashReportToJson(this);

  // Helper getters
  String get severityLabel {
    switch (severity) {
      case CrashSeverity.minor:
        return 'Minor';
      case CrashSeverity.moderate:
        return 'Moderate';
      case CrashSeverity.severe:
        return 'Severe';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String get shortLocation {
    if (address != null && address!.isNotEmpty) {
      // Return first part of address (before first comma)
      final parts = address!.split(',');
      return parts.first.trim();
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
}
