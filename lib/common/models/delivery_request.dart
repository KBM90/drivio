import 'package:drivio_app/common/models/location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delivery_request.g.dart';

@JsonSerializable()
class DeliveryRequest {
  final int id;

  @JsonKey(name: 'passenger_id')
  final int passengerId;

  @JsonKey(name: 'delivery_person_id')
  final int? deliveryPersonId;

  final String category;
  final String? description;

  @JsonKey(name: 'pickup_notes')
  final String? pickupNotes;

  @JsonKey(name: 'dropoff_notes')
  final String? dropoffNotes;

  @JsonKey(name: 'delivery_location', fromJson: _parseLocation)
  final Location? deliveryLocation;

  @JsonKey(name: 'pickup_location', fromJson: _parseLocation)
  final Location? pickupLocation;

  final String status;
  final double? price;

  @JsonKey(name: 'proposed_price')
  final double? proposedPrice;

  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  DeliveryRequest({
    required this.id,
    required this.passengerId,
    this.deliveryPersonId,
    required this.category,
    this.description,
    this.pickupNotes,
    this.dropoffNotes,
    this.deliveryLocation,
    this.pickupLocation,
    required this.status,
    this.price,
    this.proposedPrice,
    this.distanceKm,
    this.createdAt,
    this.updatedAt,
  });

  DeliveryRequest copyWith({
    int? id,
    int? passengerId,
    int? deliveryPersonId,
    String? category,
    String? description,
    String? pickupNotes,
    String? dropoffNotes,
    Location? deliveryLocation,
    Location? pickupLocation,
    String? status,
    double? price,
    double? proposedPrice,
    double? distanceKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryRequest(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      category: category ?? this.category,
      description: description ?? this.description,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      dropoffNotes: dropoffNotes ?? this.dropoffNotes,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      status: status ?? this.status,
      price: price ?? this.price,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      distanceKm: distanceKm ?? this.distanceKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DeliveryRequest.fromJson(Map<String, dynamic> json) =>
      _$DeliveryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryRequestToJson(this);

  static Location? _parseLocation(dynamic locationData) {
    if (locationData == null) return null;

    if (locationData is Map<String, dynamic>) {
      // Handle PostGIS GeoJSON format
      if (locationData['type'] == 'Point' &&
          locationData['coordinates'] is List) {
        final coords = locationData['coordinates'] as List;
        return Location(
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
        );
      }
      // Handle standard JSON
      if (locationData.containsKey('latitude')) {
        return Location.fromJson(locationData);
      }
    }
    return null;
  }
}
