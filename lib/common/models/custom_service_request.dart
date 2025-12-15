import 'package:json_annotation/json_annotation.dart';
import 'package:drivio_app/common/models/location.dart';

part 'custom_service_request.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomServiceRequest {
  final int id;

  @JsonKey(name: 'driver_id')
  final int driverId;

  // Custom service details
  @JsonKey(name: 'service_name')
  final String serviceName;

  final String category;
  final String description;

  // Request details
  final int quantity;
  final String? notes;

  @JsonKey(name: 'preferred_contact_method')
  final String preferredContactMethod; // 'phone', 'whatsapp', 'sms'

  // Driver info
  @JsonKey(name: 'driver_name')
  final String driverName;

  @JsonKey(name: 'driver_phone')
  final String driverPhone;

  @JsonKey(
    name: 'driver_location',
    fromJson: _locationFromPostGIS,
    toJson: _locationToPostGIS,
  )
  final Location? driverLocation;

  // Request status
  final String status; // 'pending', 'contacted', 'fulfilled', 'cancelled'

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  CustomServiceRequest({
    required this.id,
    required this.driverId,
    required this.serviceName,
    required this.category,
    required this.description,
    required this.quantity,
    this.notes,
    required this.preferredContactMethod,
    required this.driverName,
    required this.driverPhone,
    this.driverLocation,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomServiceRequest.fromJson(Map<String, dynamic> json) =>
      _$CustomServiceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CustomServiceRequestToJson(this);

  // Parse PostGIS Point to Location
  static Location? _locationFromPostGIS(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      // Parse "POINT(lng lat)" format
      final regex = RegExp(r'POINT\(([^ ]+) ([^ ]+)\)');
      final match = regex.firstMatch(value);
      if (match != null) {
        return Location(
          latitude: double.parse(match.group(2)!),
          longitude: double.parse(match.group(1)!),
        );
      }
    }
    return null;
  }

  // Convert Location to PostGIS Point
  static String? _locationToPostGIS(Location? location) {
    if (location == null ||
        location.longitude == null ||
        location.latitude == null) {
      return null;
    }
    return 'POINT(${location.longitude} ${location.latitude})';
  }

  @override
  String toString() {
    return 'CustomServiceRequest(id: $id, serviceName: $serviceName, '
        'category: $category, driverId: $driverId, status: $status, '
        'quantity: $quantity, createdAt: $createdAt)';
  }
}
