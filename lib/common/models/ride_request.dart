import 'dart:async';

import 'package:drivio_app/common/models/payment_method.dart';
import 'package:drivio_app/common/models/transporttype.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/passenger/models/passenger.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'location.dart'; // ✅ Import Location

part 'ride_request.g.dart';

@JsonSerializable()
class RideRequest {
  final int id;
  @JsonKey(name: 'passenger')
  final Passenger passenger; // Change from passengerId to full Passenger object
  @JsonKey(name: 'driver_id')
  final int? driverId;
  @JsonKey(name: 'driver')
  final Driver? driver; // <-- Add this
  @JsonKey(name: 'transport_type_id')
  final int? transportTypeId;
  @JsonKey(name: 'payment_method_id')
  final int? paymentMethodId;
  @JsonKey(name: 'transport_type')
  final TransportType? transportType; // Add this field
  @JsonKey(name: 'payment_method')
  final PaymentMethod? paymentMethod; // Add this field

  final String? status;
  final double? price;
  @JsonKey(name: 'pickup_location')
  final Location pickupLocation;
  @JsonKey(name: 'destination_location')
  final Location destinationLocation;
  final Map<String, dynamic>? preferences;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'estimated_time_min')
  final int? estimatedTimeMin;
  @JsonKey(name: 'requested_at')
  final DateTime? requestedAt;
  @JsonKey(name: 'accepted_at')
  final DateTime? acceptedAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'qr_code')
  final String? qrCode;
  @JsonKey(name: 'qr_code_scanned')
  final bool? qrCodeScanned;
  final String? instructions;

  RideRequest({
    required this.id,
    required this.passenger, // Update constructor
    this.driverId,
    this.driver, // Add this
    required this.transportTypeId,
    required this.paymentMethodId,
    this.transportType, // Add to constructor
    this.paymentMethod, // Add to constructor
    required this.status,
    this.price,
    required this.pickupLocation,
    required this.destinationLocation,
    this.preferences,
    this.distanceKm,
    this.estimatedTimeMin,

    this.requestedAt,
    this.acceptedAt,
    this.createdAt,
    this.updatedAt,
    this.qrCode,
    this.qrCodeScanned,
    this.instructions,
  });

  RideRequest.create({
    required this.passenger,
    this.driverId,
    this.driver,
    required this.transportTypeId,
    required this.paymentMethodId,
    this.transportType,
    this.paymentMethod,
    required this.status,
    this.price,
    required this.pickupLocation,
    required this.destinationLocation,
    this.preferences,
    this.distanceKm,
    this.estimatedTimeMin,
    this.instructions,
  }) : id = 0,
       requestedAt = null,
       acceptedAt = null,
       createdAt = null,
       updatedAt = null,
       qrCode = null,
       qrCodeScanned = null;

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    return RideRequest(
      id: json['id'] ?? 0,
      passenger: Passenger.fromJson(json['passenger'] ?? {}),
      driverId: json['driver_id'],
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      transportTypeId: json['transport_type_id'],
      transportType:
          json['transport_type'] != null
              ? TransportType.fromJson(json['transport_type'])
              : null,
      paymentMethodId: json['payment_method_id'],
      paymentMethod:
          json['payment_method'] != null
              ? PaymentMethod.fromJson(json['payment_method'])
              : null,

      status: json['status'] ?? '',
      price: (json['price'] as num?)?.toDouble(),
      preferences:
          json['preferences'] is Map<String, dynamic>
              ? json['preferences']
              : {},
      // Handle both database column names (distance) and model field names (distance_km)
      distanceKm:
          (json['distance_km'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble(),
      // Handle both database column names (duration) and model field names (estimated_time_min)
      estimatedTimeMin:
          (json['estimated_time_min'] as num?)?.toInt() ??
          (json['duration'] as num?)?.toInt(),

      requestedAt:
          json['requested_at'] != null
              ? DateTime.parse(json['requested_at'])
              : null,
      acceptedAt:
          json['accepted_at'] != null
              ? DateTime.parse(json['accepted_at'])
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      pickupLocation:
          json['pickup_location'] != null
              ? Location.fromJson(json['pickup_location'])
              : Location(latitude: null, longitude: null), // Handle null case
      destinationLocation:
          json['destination_location'] != null
              ? Location.fromJson(json['destination_location'])
              : json['dropoff_location'] != null
              ? Location.fromJson(json['dropoff_location'])
              : Location(latitude: null, longitude: null),
      qrCode: json['qr_code'] as String?,
      qrCodeScanned: json['qr_code_scanned'] as bool?,
      instructions: json['instructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$RideRequestToJson(this);

  Map<String, dynamic> toRequestJson() {
    return {
      'pickup_lat': pickupLocation.latitude,
      'pickup_lng': pickupLocation.longitude,
      'dropoff_lat': destinationLocation.latitude,
      'dropoff_lng': destinationLocation.longitude,
      'price': price,
      'distance': distanceKm,
      'duration': estimatedTimeMin,
      'transport_type_id': transportTypeId,
      'payment_method_id': paymentMethodId,
    };
  }

  // Listen to status changes (same as before)
  // Inside your RideRequest model class

  Stream<Map<String, dynamic>?> watchStatus() {
    final StreamController<Map<String, dynamic>?> controller =
        StreamController<Map<String, dynamic>?>();

    final supabase = Supabase.instance.client;

    // Track the previous status to detect changes
    String? previousStatus;

    // Get initial data
    supabase
        .from('ride_requests')
        .select()
        .eq('id', id.toString())
        .maybeSingle()
        .then((data) {
          if (!controller.isClosed && data != null) {
            previousStatus = data['status'] as String?;
            controller.add(data);
          }
        });

    // Listen to changes in real-time
    final channel =
        supabase
            .channel('ride_request_$id')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'ride_requests',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: id.toString(),
              ),
              callback: (payload) {
                if (!controller.isClosed) {
                  final newStatus = payload.newRecord['status'] as String?;

                  // Only emit if status has actually changed
                  if (newStatus != previousStatus) {
                    previousStatus = newStatus;
                    controller.add(payload.newRecord);
                  }
                }
              },
            )
            .subscribe();

    // Cleanup when stream is cancelled
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  RideRequest copyWith({
    int? id,
    Passenger? passenger,
    int? driverId,
    Driver? driver,
    int? transportTypeId,
    int? paymentMethodId,
    TransportType? transportType,
    PaymentMethod? paymentMethod,
    String? status,
    double? price,
    Location? pickupLocation,
    Location? destinationLocation,
    Map<String, dynamic>? preferences,
    double? distanceKm,
    int? estimatedTimeMin,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? qrCode,
    bool? qrCodeScanned,
    String? instructions,
  }) {
    return RideRequest(
      id: id ?? this.id,
      passenger: passenger ?? this.passenger,
      driverId: driverId ?? this.driverId,
      driver: driver ?? this.driver,
      transportTypeId: transportTypeId ?? this.transportTypeId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      transportType: transportType ?? this.transportType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      price: price ?? this.price,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      preferences: preferences ?? this.preferences,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedTimeMin: estimatedTimeMin ?? this.estimatedTimeMin,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qrCode: qrCode ?? this.qrCode,
      qrCodeScanned: qrCodeScanned ?? this.qrCodeScanned,
      instructions: instructions ?? this.instructions,
    );
  }
}
