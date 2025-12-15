// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provided_car_rental.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProvidedCarRental _$ProvidedCarRentalFromJson(Map<String, dynamic> json) =>
    ProvidedCarRental(
      id: (json['id'] as num).toInt(),
      carRenterId: (json['car_renter_id'] as num).toInt(),
      carRenter:
          json['car_renter'] == null
              ? null
              : CarRenter.fromJson(json['car_renter'] as Map<String, dynamic>),
      carBrandId: (json['car_brand_id'] as num).toInt(),
      carBrand:
          json['car_brand'] == null
              ? null
              : CarBrand.fromJson(json['car_brand'] as Map<String, dynamic>),
      year: (json['year'] as num?)?.toInt(),
      color: json['color'] as String?,
      plateNumber: json['plate_number'] as String?,
      location:
          json['location'] == null
              ? null
              : Location.fromJson(json['location'] as Map<String, dynamic>),
      city: json['city'] as String,
      dailyPrice: ProvidedCarRental._dailyPriceFromJson(json['daily_price']),
      features: json['features'] as Map<String, dynamic>?,
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isAvailable: json['is_available'] as bool? ?? true,
      unavailableFrom:
          json['unavailable_from'] == null
              ? null
              : DateTime.parse(json['unavailable_from'] as String),
      unavailableUntil:
          json['unavailable_until'] == null
              ? null
              : DateTime.parse(json['unavailable_until'] as String),
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ProvidedCarRentalToJson(ProvidedCarRental instance) =>
    <String, dynamic>{
      'id': instance.id,
      'car_renter_id': instance.carRenterId,
      'car_renter': instance.carRenter,
      'car_brand_id': instance.carBrandId,
      'car_brand': instance.carBrand,
      'year': instance.year,
      'color': instance.color,
      'plate_number': instance.plateNumber,
      'location': instance.location,
      'city': instance.city,
      'daily_price': instance.dailyPrice,
      'features': instance.features,
      'images': instance.images,
      'is_available': instance.isAvailable,
      'unavailable_from': instance.unavailableFrom?.toIso8601String(),
      'unavailable_until': instance.unavailableUntil?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
