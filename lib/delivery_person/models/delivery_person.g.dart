// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryPerson _$DeliveryPersonFromJson(Map<String, dynamic> json) =>
    DeliveryPerson(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      user:
          json['user'] == null
              ? null
              : User.fromJson(json['user'] as Map<String, dynamic>),
      vehicleType: json['vehicle_type'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      currentLocation: DeliveryPerson._parseLocation(json['current_location']),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DeliveryPersonToJson(DeliveryPerson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'user': instance.user,
      'vehicle_type': instance.vehicleType,
      'vehicle_plate': instance.vehiclePlate,
      'is_available': instance.isAvailable,
      'current_location': instance.currentLocation,
      'rating': instance.rating,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
