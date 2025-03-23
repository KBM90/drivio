import 'package:json_annotation/json_annotation.dart';
import 'location.dart'; // ✅ Import Location

part 'ride_request.g.dart';

@JsonSerializable()
class RideRequest {
  final int id;
  @JsonKey(name: 'passenger_id')
  final int passengerId;
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'transport_type_id')
  final int? transportTypeId;
  final String? status;
  final double? price;
  @JsonKey(name: 'pickup_location')
  final Location pickupLocation;
  @JsonKey(name: 'destination_location')
  final Location destinationLocation;
  final Map<String, dynamic>? preferences;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'estimated_time_min')
  final int? estimatedTimeMin;
  @JsonKey(name: 'estimated_fare')
  final double? estimatedFare;
  @JsonKey(name: 'requested_at')
  final DateTime? requestedAt;
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  RideRequest({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.transportTypeId,
    required this.status,
    this.price,
    required this.pickupLocation,
    required this.destinationLocation,
    this.preferences,
    this.distanceKm,
    this.estimatedTimeMin,
    this.estimatedFare,
    this.requestedAt,
    this.acceptedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] ?? 0,
      passengerId: json['passenger_id'] ?? 0,
      driverId: json['driver_id'],
      transportTypeId: json['transport_type_id'],
      status: json['status'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      preferences:
          json['preferences'] is Map<String, dynamic>
              ? json['preferences']
              : {},
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedTimeMin: (json['estimated_time_min'] as num?)?.toInt() ?? 0,
      estimatedFare: (json['estimated_fare'] as num?)?.toDouble() ?? 0.0,
      requestedAt:
          json['requested_at'] != null
              ? DateTime.parse(json['requested_at'])
              : null,
      acceptedAt:
          json['accepted_at'] != null
              ? DateTime.parse(json['accepted_at'])
              : null,
      pickupLocation: Location.fromJson(json['pickup_location'] ?? {}),
      destinationLocation: Location.fromJson(
        json['destination_location'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => _$RideRequestToJson(this);
}
