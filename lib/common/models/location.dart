// location.dart
import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location {
  final double? latitude;
  final double? longitude;

  Location({this.latitude, this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    // Handle GeoJSON format: {"type": "Point", "coordinates": [longitude, latitude]}
    if (json.containsKey('coordinates') && json['coordinates'] is List) {
      final coordinates = json['coordinates'] as List;
      if (coordinates.length >= 2) {
        return Location(
          latitude: (coordinates[1] as num?)?.toDouble(),
          longitude: (coordinates[0] as num?)?.toDouble(),
        );
      }
    }

    // Handle standard format
    return Location(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
