// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passenger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Passenger _$PassengerFromJson(Map<String, dynamic> json) => Passenger(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  user:
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
  location:
      json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
  preferences: json['preferences'] as Map<String, dynamic>?,
  drivingDistance: (json['driving_distance'] as num?)?.toDouble(),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$PassengerToJson(Passenger instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'user': instance.user,
  'location': instance.location,
  'preferences': instance.preferences,
  'driving_distance': instance.drivingDistance,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
