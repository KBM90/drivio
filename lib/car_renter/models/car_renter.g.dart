// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_renter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarRenter _$CarRenterFromJson(Map<String, dynamic> json) => CarRenter(
  id: CarRenter._idFromJson(json['id']),
  userId: CarRenter._userIdFromJson(json['user_id']),
  user:
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
  businessName: json['business_name'] as String?,
  location:
      json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
  city: json['city'] as String?,
  rating: (json['rating'] as num?)?.toDouble(),
  totalCars: (json['total_cars'] as num?)?.toInt(),
  isVerified: json['is_verified'] as bool? ?? false,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CarRenterToJson(CarRenter instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'user': instance.user,
  'business_name': instance.businessName,
  'location': instance.location,
  'city': instance.city,
  'rating': instance.rating,
  'total_cars': instance.totalCars,
  'is_verified': instance.isVerified,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
