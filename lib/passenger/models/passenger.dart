// passenger.dart
import 'package:drivio_app/common/models/location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'passenger.g.dart';

@JsonSerializable()
class Passenger {
  final int id;
  final int userId;
  final String name; // Add name field
  final Location? location;
  final Map<String, dynamic> preferences;
  final double drivingDistance;

  Passenger({
    required this.id,
    required this.userId,
    required this.name, // Add to constructor
    required this.location,
    required this.preferences,
    required this.drivingDistance,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: json['id'],
      userId: json['userId'],
      name: json['name'], // Add from JSON
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      preferences: json['preferences'] ?? {},
      drivingDistance: (json['drivingDistance'] as num?)?.toDouble() ?? 0.0,
    );
  }
  Map<String, dynamic> toJson() => _$PassengerToJson(this);
}
