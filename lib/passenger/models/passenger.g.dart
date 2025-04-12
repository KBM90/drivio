// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passenger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Passenger _$PassengerFromJson(Map<String, dynamic> json) => Passenger(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  name: json['name'] as String,
  location:
      json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
  preferences: json['preferences'] as Map<String, dynamic>,
  drivingDistance: (json['drivingDistance'] as num).toDouble(),
);

Map<String, dynamic> _$PassengerToJson(Passenger instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'name': instance.name,
  'location': instance.location,
  'preferences': instance.preferences,
  'drivingDistance': instance.drivingDistance,
};
