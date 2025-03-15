// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Driver _$DriverFromJson(Map<String, dynamic> json) => Driver(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  location:
      json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
  dropoffLocation:
      json['dropoff_location'] == null
          ? null
          : Location.fromJson(json['dropoff_location'] as Map<String, dynamic>),
  preferences: json['preferences'] as Map<String, dynamic>?,
  drivingDistance: (json['driving_distance'] as num?)?.toDouble(),
  status: json['status'] as bool,
);

Map<String, dynamic> _$DriverToJson(Driver instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'location': instance.location,
  'dropoff_location': instance.dropoffLocation,
  'preferences': instance.preferences,
  'driving_distance': instance.drivingDistance,
  'status': instance.status,
};

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
