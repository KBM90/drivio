// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceOrder _$ServiceOrderFromJson(Map<String, dynamic> json) => ServiceOrder(
  id: (json['id'] as num).toInt(),
  serviceId: (json['service_id'] as num?)?.toInt(),
  requesterUserId: (json['requester_user_id'] as num).toInt(),
  providerId: (json['provider_id'] as num?)?.toInt(),
  customServiceName: json['custom_service_name'] as String?,
  category: json['category'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  notes: json['notes'] as String?,
  preferredContactMethod: json['preferred_contact_method'] as String,
  requesterName: json['requester_name'] as String,
  requesterPhone: json['requester_phone'] as String,
  requesterLocation: ServiceOrder._locationFromPostGIS(
    json['requester_location'],
  ),
  status: json['status'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  serviceDetails: json['provided_services'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ServiceOrderToJson(ServiceOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service_id': instance.serviceId,
      'requester_user_id': instance.requesterUserId,
      'provider_id': instance.providerId,
      'custom_service_name': instance.customServiceName,
      'category': instance.category,
      'quantity': instance.quantity,
      'notes': instance.notes,
      'preferred_contact_method': instance.preferredContactMethod,
      'requester_name': instance.requesterName,
      'requester_phone': instance.requesterPhone,
      'requester_location': ServiceOrder._locationToPostGIS(
        instance.requesterLocation,
      ),
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
