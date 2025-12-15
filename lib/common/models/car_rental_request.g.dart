// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_rental_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarRentalRequest _$CarRentalRequestFromJson(Map<String, dynamic> json) =>
    CarRentalRequest(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      carRentalId: (json['car_rental_id'] as num).toInt(),
      carRental:
          json['car_rental'] == null
              ? null
              : ProvidedCarRental.fromJson(
                json['car_rental'] as Map<String, dynamic>,
              ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalDays: (json['total_days'] as num?)?.toInt(),
      totalPrice: (json['total_price'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CarRentalRequestToJson(CarRentalRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'car_rental_id': instance.carRentalId,
      'car_rental': instance.carRental,
      'start_date': instance.startDate.toIso8601String(),
      'end_date': instance.endDate.toIso8601String(),
      'total_days': instance.totalDays,
      'total_price': instance.totalPrice,
      'status': instance.status,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
