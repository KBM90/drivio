// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String?,
  countryCode: json['countryCode'] as String?,
  sexe: json['sexe'] as String?,
  city: json['city'] as String?,
  role: json['role'] as String?,
  language: json['language'] as String?,
  country: json['country'] as String?,
  profileImagePath: json['profile_image_path'] as String?,
  banned: json['banned'] as bool? ?? false,
  emailVerifiedAt:
      json['email_verified_at'] == null
          ? null
          : DateTime.parse(json['email_verified_at'] as String),
  isVerified: json['is_verified'] as bool? ?? false,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  userId: json['user_id'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'countryCode': instance.countryCode,
  'sexe': instance.sexe,
  'city': instance.city,
  'role': instance.role,
  'language': instance.language,
  'country': instance.country,
  'profile_image_path': instance.profileImagePath,
  'banned': instance.banned,
  'email_verified_at': instance.emailVerifiedAt?.toIso8601String(),
  'is_verified': instance.isVerified,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'user_id': instance.userId,
};
