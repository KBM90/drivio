import 'package:drivio_app/common/models/car_brand.dart';

class Vehicle {
  final int id;
  final int driverId;
  final int carBrandId;
  final int transportTypeId;
  final String licensePlate;
  final String? color;
  final bool? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CarBrand? carBrand; // Nested car brand data

  Vehicle({
    required this.id,
    required this.driverId,
    required this.carBrandId,
    required this.transportTypeId,
    required this.licensePlate,
    this.color,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.carBrand,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      carBrandId: json['car_brand_id'] as int,
      transportTypeId: json['transport_type_id'] as int,
      licensePlate: json['license_plate'] as String,
      color: json['color'] as String?,
      status: json['status'] as bool?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      carBrand:
          json['car_brands'] != null
              ? CarBrand.fromJson(json['car_brands'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'car_brand_id': carBrandId,
      'transport_type_id': transportTypeId,
      'license_plate': licensePlate,
      'color': color,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get displayName {
    if (carBrand != null) {
      return '${carBrand!.company} ${carBrand!.model}';
    }
    return 'Vehicle';
  }
}
