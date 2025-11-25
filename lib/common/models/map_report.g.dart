// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapReport _$MapReportFromJson(Map<String, dynamic> json) => MapReport(
  id: (json['id'] as num).toInt(),
  reportType: json['report_type'] as String,
  pointLocation: MapReport._locationFromPostGIS(json['point_location']),
  routePoints: MapReport._locationListFromJson(json['route_points'] as List?),
  userId: (json['user_id'] as num?)?.toInt(),
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
  'point_location': MapReport._locationToPostGIS(instance.pointLocation),
  'route_points': instance.routePoints?.map((e) => e.toJson()).toList(),
  'user_id': instance.userId,
  'user': instance.user?.toJson(),
  'status': instance.status,
  'description': instance.description,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
