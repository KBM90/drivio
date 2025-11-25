import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:json_annotation/json_annotation.dart';
import 'location.dart';
import 'user.dart';

part 'map_report.g.dart';

@JsonSerializable(explicitToJson: true)
class MapReport {
  final int id;

  @JsonKey(name: 'report_type')
  final String reportType;

  @JsonKey(name: 'point_location', fromJson: _locationFromPostGIS, toJson: _locationToPostGIS)
  final Location? pointLocation;

  @JsonKey(name: 'route_points', fromJson: _locationListFromJson)
  final List<Location>? routePoints;

  @JsonKey(name: 'user_id')
  final int? userId;

  // Optional: Include User object if fetched via join
  final User? user;

  @JsonKey(defaultValue: 'Active')
  final String status;

  final String? description;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  MapReport({
    required this.id,
    required this.reportType,
    this.pointLocation,
    this.routePoints,
    this.userId,
    this.user,
    this.status = 'Active',
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MapReport.fromJson(Map<String, dynamic> json) =>
      _$MapReportFromJson(json);
  Map<String, dynamic> toJson() => _$MapReportToJson(this);

  // Custom converter for route_points (jsonb)
  static List<Location>? _locationListFromJson(List<dynamic>? json) {
    if (json == null) return null;
    return json
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Custom converter for point_location (geometry)
  static Location? _locationFromPostGIS(dynamic point) {
    if (point == null) return null;
    if (point is String) {
      final coords = GeolocatorHelper.parsePostGISPoint(point);
      return Location(
        latitude: coords['latitude'],
        longitude: coords['longitude'],
      );
    }
    return null;
  }

  static String? _locationToPostGIS(Location? location) {
    if (location == null || location.longitude == null || location.latitude == null) return null;
    return 'POINT(${location.longitude} ${location.latitude})';
  }

  @override
  String toString() {
    return 'MapReport(id: $id, reportType: $reportType, pointLocation: $pointLocation, '
        'routePoints: $routePoints, userId: $userId, status: $status, '
        'description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
