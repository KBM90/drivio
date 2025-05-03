import 'package:json_annotation/json_annotation.dart';
import 'location.dart';
import 'user.dart';

part 'map_report.g.dart';

@JsonSerializable(explicitToJson: true)
class MapReport {
  final int id;

  @JsonKey(name: 'report_type')
  final String reportType;

  @JsonKey(name: 'point_latitude')
  final double? pointLatitude;

  @JsonKey(name: 'point_longitude')
  final double? pointLongitude;

  @JsonKey(name: 'route_points', fromJson: _locationListFromJson)
  final List<Location>? routePoints;

  final User? user;
  final String status;
  final String? description;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  MapReport({
    required this.id,
    required this.reportType,
    this.pointLatitude,
    this.pointLongitude,
    this.routePoints,
    this.user,
    this.status = 'Active',
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MapReport.fromJson(Map<String, dynamic> json) =>
      _$MapReportFromJson(json);
  Map<String, dynamic> toJson() => _$MapReportToJson(this);

  // Custom converter for route_points
  static List<Location>? _locationListFromJson(List<dynamic>? json) {
    if (json == null) return null;
    return json
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Location? get pointLocation =>
      (pointLatitude != null && pointLongitude != null)
          ? Location(latitude: pointLatitude, longitude: pointLongitude)
          : null;

  @override
  String toString() {
    return 'MapReport(id: $id, reportType: $reportType, pointLocation: $pointLocation, '
        'routePoints: $routePoints, user: $user, status: $status, '
        'description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
