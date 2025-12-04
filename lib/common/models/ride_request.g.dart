// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RideRequest _$RideRequestFromJson(Map<String, dynamic> json) => RideRequest(
  id: (json['id'] as num).toInt(),
  passenger: Passenger.fromJson(json['passenger'] as Map<String, dynamic>),
  driverId: (json['driver_id'] as num?)?.toInt(),
  driver:
      json['driver'] == null
          ? null
          : Driver.fromJson(json['driver'] as Map<String, dynamic>),
  transportTypeId: (json['transport_type_id'] as num?)?.toInt(),
  paymentMethodId: (json['payment_method_id'] as num?)?.toInt(),
  transportType:
      json['transport_type'] == null
          ? null
          : TransportType.fromJson(
            json['transport_type'] as Map<String, dynamic>,
          ),
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
  qrCode: json['qr_code'] as String?,
  qrCodeScanned: json['qr_code_scanned'] as bool?,
);

Map<String, dynamic> _$RideRequestToJson(RideRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'passenger': instance.passenger,
      'driver_id': instance.driverId,
      'driver': instance.driver,
      'transport_type_id': instance.transportTypeId,
      'payment_method_id': instance.paymentMethodId,
      'transport_type': instance.transportType,
      'status': instance.status,
      'price': instance.price,
      'pickup_location': instance.pickupLocation,
      'destination_location': instance.destinationLocation,
      'preferences': instance.preferences,
      'distance_km': instance.distanceKm,
      'estimated_time_min': instance.estimatedTimeMin,
      'requested_at': instance.requestedAt?.toIso8601String(),
      'accepted_at': instance.acceptedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'qr_code': instance.qrCode,
      'qr_code_scanned': instance.qrCodeScanned,
    };
