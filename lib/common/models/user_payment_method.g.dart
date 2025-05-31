// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_payment_method.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPaymentMethod _$UserPaymentMethodFromJson(Map<String, dynamic> json) =>
    UserPaymentMethod(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      paymentMethodId: (json['payment_method_id'] as num).toInt(),
      details: json['details'] as Map<String, dynamic>?,
      isDefault: json['is_default'] as bool,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserPaymentMethodToJson(UserPaymentMethod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'payment_method_id': instance.paymentMethodId,
      'details': instance.details,
      'is_default': instance.isDefault,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
