import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delivery_person.g.dart';

@JsonSerializable()
class DeliveryPerson {
  final int id;

  @JsonKey(name: 'user_id')
  final int userId;

  final User? user;

  @JsonKey(name: 'vehicle_type')
  final String? vehicleType;

  @JsonKey(name: 'vehicle_plate')
  final String? vehiclePlate;

  @JsonKey(name: 'is_available')
  final bool isAvailable;

  @JsonKey(name: 'current_location', fromJson: _parseLocation)
  final Location? currentLocation;

  final double rating;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  DeliveryPerson({
    required this.id,
    required this.userId,
    this.user,
    this.vehicleType,
    this.vehiclePlate,
    this.isAvailable = true,
    this.currentLocation,
    this.rating = 5.0,
    this.createdAt,
    this.updatedAt,
  });

  factory DeliveryPerson.fromJson(Map<String, dynamic> json) =>
      _$DeliveryPersonFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryPersonToJson(this);

  static Location? _parseLocation(dynamic locationData) {
    if (locationData == null) return null;

    if (locationData is Map<String, dynamic>) {
      // Handle PostGIS GeoJSON format
      if (locationData['type'] == 'Point' &&
          locationData['coordinates'] is List) {
        final coords = locationData['coordinates'] as List;
        return Location(
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
        );
      }
      // Handle standard JSON
      if (locationData.containsKey('latitude')) {
        return Location.fromJson(locationData);
      }
    }
    return null;
  }
}
