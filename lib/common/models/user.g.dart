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
  sexe: json['sexe'] as String?,
  city: json['city'] as String?,
  role: json['role'] as String? ?? 'user',
  profile_image_path: json['profile_image_path'] as String?,
  banned: json['banned'] as bool? ?? false,
  email_verified_at:
      json['email_verified_at'] == null
          ? null
          : DateTime.parse(json['email_verified_at'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'sexe': instance.sexe,
  'city': instance.city,
  'role': instance.role,
  'profile_image_path': instance.profile_image_path,
  'banned': instance.banned,
  'email_verified_at': instance.email_verified_at?.toIso8601String(),
};
