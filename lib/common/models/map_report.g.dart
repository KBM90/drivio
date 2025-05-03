// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapReport _$MapReportFromJson(Map<String, dynamic> json) => MapReport(
  id: (json['id'] as num).toInt(),
  reportType: json['report_type'] as String,
  pointLatitude: (json['point_latitude'] as num?)?.toDouble(),
  pointLongitude: (json['point_longitude'] as num?)?.toDouble(),
  routePoints: MapReport._locationListFromJson(json['route_points'] as List?),
  user:
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
  status: json['status'] as String? ?? 'Active',
  description: json['description'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$MapReportToJson(MapReport instance) => <String, dynamic>{
  'id': instance.id,
  'report_type': instance.reportType,
  'point_latitude': instance.pointLatitude,
  'point_longitude': instance.pointLongitude,
  'route_points': instance.routePoints?.map((e) => e.toJson()).toList(),
  'user': instance.user?.toJson(),
  'status': instance.status,
  'description': instance.description,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
