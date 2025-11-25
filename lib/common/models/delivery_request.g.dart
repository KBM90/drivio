// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryRequest _$DeliveryRequestFromJson(Map<String, dynamic> json) =>
    DeliveryRequest(
      id: (json['id'] as num).toInt(),
      passengerId: (json['passenger_id'] as num).toInt(),
      deliveryPersonId: (json['delivery_person_id'] as num?)?.toInt(),
      category: json['category'] as String,
      description: json['description'] as String?,
      pickupNotes: json['pickup_notes'] as String?,
      dropoffNotes: json['dropoff_notes'] as String?,
      deliveryLocation: DeliveryRequest._parseLocation(
        json['delivery_location'],
      ),
      pickupLocation: DeliveryRequest._parseLocation(json['pickup_location']),
      status: json['status'] as String,
      price: (json['price'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DeliveryRequestToJson(DeliveryRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'passenger_id': instance.passengerId,
      'delivery_person_id': instance.deliveryPersonId,
      'category': instance.category,
      'description': instance.description,
      'pickup_notes': instance.pickupNotes,
      'dropoff_notes': instance.dropoffNotes,
      'delivery_location': instance.deliveryLocation,
      'pickup_location': instance.pickupLocation,
      'status': instance.status,
      'price': instance.price,
      'distance_km': instance.distanceKm,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
