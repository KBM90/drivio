// passenger.dart
import 'dart:convert';

import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'passenger.g.dart';

@JsonSerializable()
class Passenger {
  final int id;

  @JsonKey(name: 'user_id') // Changed from 'userId' to match DB snake_case
  final int userId;

  final User? user; // This will be populated via join

  // REMOVED: name field - doesn't exist in passengers table
  // The name should come from the User object via the join

  final Location? location; // Keep this, will parse from geometry

  final Map<String, dynamic>? preferences;

  @JsonKey(name: 'driving_distance') // Changed from drivingDistance to match DB
  final double? drivingDistance; // Made nullable to match DB default

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Passenger({
    required this.id,
    required this.userId,
    this.user,
    this.location,
    this.preferences,
    this.drivingDistance,
    this.createdAt,
    this.updatedAt,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    // Helper function to parse location from PostGIS geometry
    Location? parseLocation(dynamic locationData) {
      if (locationData == null) {
        return null;
      }

      // If it's already a Map with latitude/longitude
      if (locationData is Map<String, dynamic> &&
          locationData.containsKey('latitude')) {
        return Location.fromJson(locationData);
      }

      // If it's GeoJSON format from PostGIS
      if (locationData is Map<String, dynamic> &&
          locationData['type'] == 'Point') {
        final coords = locationData['coordinates'] as List;
        return Location(
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
        );
      }

      return null;
    }

    User? parsedUser;
    try {
      if (json['user'] != null) {
        parsedUser = User.fromJson(json['user'] as Map<String, dynamic>);
      } else {
        debugPrint('⚠️ User data is null in JSON');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error parsing user: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      parsedUser = null;
    }

    return Passenger(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      user: parsedUser,
      location: parseLocation(json['location']),
      preferences:
          json['preferences'] is Map
              ? Map<String, dynamic>.from(json['preferences'] as Map)
              : (json['preferences'] is String
                  ? jsonDecode(json['preferences']) as Map<String, dynamic>
                  : null),
      drivingDistance: (json['driving_distance'] as num?)?.toDouble(),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() => _$PassengerToJson(this);

  // Helper method to get passenger name from user
  String get name => user?.name ?? 'Unknown';

  // Convenience getters for UI
  String get firstName => name.split(' ').first;
  String get lastName =>
      name.split(' ').length > 1 ? name.split(' ').sublist(1).join(' ') : '';
  String? get profileImage => user?.profileImagePath;
  String? get phoneNumber => user?.phone;
  double? get rating =>
      5.0; // Placeholder as rating is not in User or Passenger model yet

  // Method to convert for API requests (if needed)
  Map<String, dynamic> toRequestJson() {
    return {
      'user_id': userId,
      if (location != null)
        'location':
            'SRID=4326;POINT(${location!.longitude} ${location!.latitude})',
      if (preferences != null) 'preferences': preferences,
      if (drivingDistance != null) 'driving_distance': drivingDistance,
    };
  }
}
