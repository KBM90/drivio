// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverDocument _$DriverDocumentFromJson(Map<String, dynamic> json) =>
    DriverDocument(
      id: (json['id'] as num).toInt(),
      driverId: (json['driver_id'] as num).toInt(),
      type: json['type'] as String,
      number: json['number'] as String,
      expiringDate: DateTime.parse(json['expiring_date'] as String),
      imageId: (json['image_id'] as num?)?.toInt(),
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
      imagePath: json['image_path'] as String?,
    );

Map<String, dynamic> _$DriverDocumentToJson(DriverDocument instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver_id': instance.driverId,
      'type': instance.type,
      'number': instance.number,
      'expiring_date': instance.expiringDate.toIso8601String(),
      'image_id': instance.imageId,
      'is_verified': instance.isVerified,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'image_path': instance.imagePath,
    };
