// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceOrder _$ServiceOrderFromJson(Map<String, dynamic> json) => ServiceOrder(
  id: (json['id'] as num).toInt(),
  serviceId: (json['service_id'] as num?)?.toInt(),
  driverId: (json['driver_id'] as num).toInt(),
  providerId: (json['provider_id'] as num?)?.toInt(),
  customServiceName: json['custom_service_name'] as String?,
  category: json['category'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  notes: json['notes'] as String?,
  preferredContactMethod: json['preferred_contact_method'] as String,
  driverName: json['driver_name'] as String,
  driverPhone: json['driver_phone'] as String,
  driverLocation: ServiceOrder._locationFromPostGIS(json['driver_location']),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  serviceDetails: json['provided_services'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ServiceOrderToJson(
  ServiceOrder instance,
) => <String, dynamic>{
  'id': instance.id,
  'service_id': instance.serviceId,
  'driver_id': instance.driverId,
  'provider_id': instance.providerId,
  'custom_service_name': instance.customServiceName,
  'category': instance.category,
  'quantity': instance.quantity,
  'notes': instance.notes,
  'preferred_contact_method': instance.preferredContactMethod,
  'driver_name': instance.driverName,
  'driver_phone': instance.driverPhone,
  'driver_location': ServiceOrder._locationToPostGIS(instance.driverLocation),
  'status': instance.status,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
