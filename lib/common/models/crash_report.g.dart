// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crash_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CrashReport _$CrashReportFromJson(Map<String, dynamic> json) => CrashReport(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  rideId: (json['ride_id'] as num?)?.toInt(),
  severity: $enumDecode(_$CrashSeverityEnumMap, json['severity']),
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  address: json['address'] as String?,
  description: json['description'] as String?,
  injuriesReported: json['injuries_reported'] as bool? ?? false,
  vehiclesInvolved: (json['vehicles_involved'] as num?)?.toInt() ?? 1,
  policeNotified: json['police_notified'] as bool? ?? false,
  photos:
      (json['photos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  emergencyContacted:
      (json['emergency_contacted'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CrashReportToJson(CrashReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'ride_id': instance.rideId,
      'severity': _$CrashSeverityEnumMap[instance.severity]!,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'description': instance.description,
      'injuries_reported': instance.injuriesReported,
      'vehicles_involved': instance.vehiclesInvolved,
      'police_notified': instance.policeNotified,
      'photos': instance.photos,
      'emergency_contacted': instance.emergencyContacted,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

const _$CrashSeverityEnumMap = {
  CrashSeverity.minor: 'minor',
  CrashSeverity.moderate: 'moderate',
  CrashSeverity.severe: 'severe',
};
