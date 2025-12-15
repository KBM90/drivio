import 'package:drivio_app/car_renter/models/car_renter.dart';
import 'package:drivio_app/common/models/car_brand.dart';
import 'package:drivio_app/common/models/location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'provided_car_rental.g.dart';

// for ProvidedCarRental model we don't need model field , also in the table , because i already have car_brands table which contains car brand field and model field , we will fetch the brand and model from there

@JsonSerializable()
class ProvidedCarRental {
  final int id;
  @JsonKey(name: 'car_renter_id')
  final int carRenterId;
  @JsonKey(name: 'car_renter')
  final CarRenter? carRenter;
  @JsonKey(name: 'car_brand_id')
  final int carBrandId;
  @JsonKey(name: 'car_brand')
  final CarBrand? carBrand;
  final int? year;
  final String? color;
  @JsonKey(name: 'plate_number')
  final String? plateNumber;
  final Location? location;
  final String city;
  @JsonKey(name: 'daily_price', fromJson: _dailyPriceFromJson)
  final double dailyPrice;
  final Map<String, dynamic>? features;

  static double _dailyPriceFromJson(dynamic value) {
    if (value == null) return 0.0;
    return (value as num).toDouble();
  }

  final List<String>? images;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'unavailable_from')
  final DateTime? unavailableFrom;
  @JsonKey(name: 'unavailable_until')
  final DateTime? unavailableUntil;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Calculated field for distance from user
  @JsonKey(includeFromJson: false, includeToJson: false)
  final double? distance;

  ProvidedCarRental({
    required this.id,
    required this.carRenterId,
    this.carRenter,
    required this.carBrandId,
    this.carBrand,
    this.year,
    this.color,
    this.plateNumber,
    this.location,
    required this.city,
    required this.dailyPrice,
    this.features,
    this.images,
    this.isAvailable = true,
    this.unavailableFrom,
    this.unavailableUntil,
    this.createdAt,
    this.updatedAt,
    this.distance,
  });

  factory ProvidedCarRental.fromJson(Map<String, dynamic> json) =>
      _$ProvidedCarRentalFromJson(json);

  Map<String, dynamic> toJson() => _$ProvidedCarRentalToJson(this);

  ProvidedCarRental copyWith({double? distance}) {
    return ProvidedCarRental(
      id: id,
      carRenterId: carRenterId,
      carRenter: carRenter,
      carBrandId: carBrandId,
      carBrand: carBrand,
      year: year,
      color: color,
      plateNumber: plateNumber,
      location: location,
      city: city,
      dailyPrice: dailyPrice,
      features: features,
      images: images,
      isAvailable: isAvailable,
      unavailableFrom: unavailableFrom,
      unavailableUntil: unavailableUntil,
      createdAt: createdAt,
      updatedAt: updatedAt,
      distance: distance ?? this.distance,
    );
  }

  String get displayName {
    if (carBrand != null) {
      // Show company + model + year when carBrand is loaded
      return '${carBrand!.company} ${carBrand!.model}${year != null ? ' ($year)' : ''}';
    }
    // Fallback when carBrand is not loaded
    return 'Car${year != null ? ' ($year)' : ''}';
  }

  String get brandName {
    if (carBrand != null) {
      return '${carBrand!.company} ${carBrand!.model}';
    }
    return 'Car Brand ID: $carBrandId';
  }
}
