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
  role: json['role'] as String?,
  profileImagePath: json['profile_image_path'] as String?,
  banned: json['banned'] as bool? ?? false,
  emailVerifiedAt:
      json['email_verified_at'] == null
          ? null
          : DateTime.parse(json['email_verified_at'] as String),
  rememberToken: json['remember_token'] as String?,
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
  'sexe': instance.sexe,
  'city': instance.city,
  'role': instance.role,
  'profile_image_path': instance.profileImagePath,
  'banned': instance.banned,
  'email_verified_at': instance.emailVerifiedAt?.toIso8601String(),
  'remember_token': instance.rememberToken,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'user_id': instance.userId,
};
