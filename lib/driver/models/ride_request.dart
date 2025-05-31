import 'package:drivio_app/common/models/transporttype.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/passenger/models/passenger.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../common/models/location.dart'; // ✅ Import Location

part 'ride_request.g.dart';

@JsonSerializable()
class RideRequest {
  final int id;
  @JsonKey(name: 'passenger')
  final Passenger passenger; // Change from passengerId to full Passenger object
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'driver')
  final Driver? driver; // <-- Add this
  @JsonKey(name: 'transport_type_id')
  final int? transportTypeId;
  @JsonKey(name: 'payment_method_id')
  final int? paymentMethodId;
  @JsonKey(name: 'transport_type')
  final TransportType? transportType; // Add this field

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
    required this.passenger, // Update constructor
    this.driverId,
    this.driver, // Add this
    required this.transportTypeId,
    required this.paymentMethodId,
    this.transportType, // Add to constructor
    required this.status,
    this.price,
    required this.pickupLocation,
    required this.destinationLocation,
    this.preferences,
    this.distanceKm,
    this.estimatedTimeMin,

    this.requestedAt,
    this.acceptedAt,
    this.createdAt,
    this.updatedAt,
  });

  RideRequest.create({
    required this.passenger,
    this.driverId,
    this.driver,
    required this.transportTypeId,
    required this.paymentMethodId,
    this.transportType,
    required this.status,
    this.price,
    required this.pickupLocation,
    required this.destinationLocation,
    this.preferences,
    this.distanceKm,
    this.estimatedTimeMin,
  }) : id = 0,
       requestedAt = null,
       acceptedAt = null,
       createdAt = null,
       updatedAt = null;

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] ?? 0,
      passenger: Passenger.fromJson(json['passenger'] ?? {}),
      driverId: json['driver_id'],
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      transportTypeId: json['transport_type_id'],
      transportType:
          json['transport_type'] != null
              ? TransportType.fromJson(json['transport_type'])
              : null,
      paymentMethodId: json['payment_method_id'],

      status: json['status'] ?? '',
      price: (json['price'] as num?)?.toDouble(),
      preferences:
          json['preferences'] is Map<String, dynamic>
              ? json['preferences']
              : {},
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      estimatedTimeMin: (json['estimated_time_min'] as num?)?.toInt(),

      requestedAt:
          json['requested_at'] != null
              ? DateTime.parse(json['requested_at'])
              : null,
      acceptedAt:
          json['accepted_at'] != null
              ? DateTime.parse(json['accepted_at'])
              : null,
      pickupLocation:
          json['pickup_location'] != null
              ? Location.fromJson(json['pickup_location'])
              : Location(latitude: null, longitude: null), // Handle null case
      destinationLocation:
          json['destination_location'] != null
              ? Location.fromJson(json['destination_location'])
              : Location(latitude: null, longitude: null),
    );
  }

  Map<String, dynamic> toJson() => _$RideRequestToJson(this);

  Map<String, dynamic> toRequestJson() {
    return {
      'pickup_lat': pickupLocation.latitude,
      'pickup_lng': pickupLocation.longitude,
      'dropoff_lat': destinationLocation.latitude,
      'dropoff_lng': destinationLocation.longitude,
      'price': price,
      'distance': distanceKm,
      'duration': estimatedTimeMin,
      'transport_type_id': transportTypeId,
      'payment_method_id': paymentMethodId,
    };
  }
}
