// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RideRequest _$RideRequestFromJson(Map<String, dynamic> json) => RideRequest(
  id: (json['id'] as num).toInt(),
  passengerId: (json['passenger_id'] as num).toInt(),
  driverId: (json['driver_id'] as num?)?.toInt(),
  transportTypeId: (json['transport_type_id'] as num?)?.toInt(),
  status: json['status'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  pickupLocation: Location.fromJson(
    json['pickup_location'] as Map<String, dynamic>,
  ),
  destinationLocation: Location.fromJson(
    json['destination_location'] as Map<String, dynamic>,
  ),
  preferences: json['preferences'] as Map<String, dynamic>?,
  distanceKm: (json['distance_km'] as num?)?.toDouble(),
  estimatedTimeMin: (json['estimated_time_min'] as num?)?.toInt(),
  estimatedFare: (json['estimated_fare'] as num?)?.toDouble(),
  requestedAt:
      json['requested_at'] == null
          ? null
          : DateTime.parse(json['requested_at'] as String),
  acceptedAt:
      json['accepted_at'] == null
          ? null
          : DateTime.parse(json['accepted_at'] as String),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$RideRequestToJson(RideRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'passenger_id': instance.passengerId,
      'driver_id': instance.driverId,
      'transport_type_id': instance.transportTypeId,
      'status': instance.status,
      'price': instance.price,
      'pickup_location': instance.pickupLocation,
      'destination_location': instance.destinationLocation,
      'preferences': instance.preferences,
      'distance_km': instance.distanceKm,
      'estimated_time_min': instance.estimatedTimeMin,
      'estimated_fare': instance.estimatedFare,
      'requested_at': instance.requestedAt?.toIso8601String(),
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
