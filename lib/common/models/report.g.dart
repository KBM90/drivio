// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Report _$ReportFromJson(Map<String, dynamic> json) => Report(
  id: (json['id'] as num?)?.toInt(),
  reportedBy: (json['reported_by'] as num).toInt(),
  reportedUser: (json['reported_user'] as num).toInt(),
  reason: json['reason'] as String,
  details: json['details'] as String?,
  status: json['status'] as String? ?? 'pending',
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ReportToJson(Report instance) => <String, dynamic>{
  'id': instance.id,
  'reported_by': instance.reportedBy,
  'reported_user': instance.reportedUser,
  'reason': instance.reason,
  'details': instance.details,
  'status': instance.status,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
