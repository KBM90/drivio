import 'package:json_annotation/json_annotation.dart';

part 'driver.g.dart';

@JsonSerializable()
class Driver {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final Location? location;
  @JsonKey(name: 'dropoff_location')
  final Location? dropoffLocation;
  final Map<String, dynamic>? preferences;
  @JsonKey(name: 'driving_distance')
  final double? drivingDistance;
  final bool status;

  Driver({
    required this.id,
    required this.userId,
    this.location,
    this.dropoffLocation,
    this.preferences,
    this.drivingDistance,
    required this.status,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);
  Map<String, dynamic> toJson() => _$DriverToJson(this);
}

@JsonSerializable()
class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
