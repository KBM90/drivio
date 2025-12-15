// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_service_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomServiceRequest _$CustomServiceRequestFromJson(
  Map<String, dynamic> json,
) => CustomServiceRequest(
  id: (json['id'] as num).toInt(),
  driverId: (json['driver_id'] as num).toInt(),
  serviceName: json['service_name'] as String,
  category: json['category'] as String,
  description: json['description'] as String,
  quantity: (json['quantity'] as num).toInt(),
  notes: json['notes'] as String?,
  preferredContactMethod: json['preferred_contact_method'] as String,
  driverName: json['driver_name'] as String,
  driverPhone: json['driver_phone'] as String,
  driverLocation: CustomServiceRequest._locationFromPostGIS(
    json['driver_location'],
  ),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CustomServiceRequestToJson(
  CustomServiceRequest instance,
) => <String, dynamic>{
  'id': instance.id,
  'driver_id': instance.driverId,
  'service_name': instance.serviceName,
  'category': instance.category,
  'description': instance.description,
  'quantity': instance.quantity,
  'notes': instance.notes,
  'preferred_contact_method': instance.preferredContactMethod,
  'driver_name': instance.driverName,
  'driver_phone': instance.driverPhone,
  'driver_location': CustomServiceRequest._locationToPostGIS(
    instance.driverLocation,
  ),
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
