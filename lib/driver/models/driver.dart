import 'package:drivio_app/common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../common/models/location.dart'; // ✅ Import Location

part 'driver.g.dart';

@JsonSerializable()
class Driver {
  final int? id;
  @JsonKey(name: 'user_id')
  final int? userId;
  final User? user;
  final Location? location;
  @JsonKey(name: 'dropoff_location')
  final Location? dropoffLocation;
  final Map<String, dynamic>? preferences;
  @JsonKey(name: 'driving_distance')
  final double? drivingDistance;
  DriverStatus? status; // ✅ Change from bool to DriverStatus enum
  int? acceptNewRequest;
  double? range;

  Driver({
    required this.id,
    this.userId,
    this.user,
    this.location,
    this.dropoffLocation,
    this.preferences,
    this.drivingDistance,
    this.status,
    this.acceptNewRequest,
    this.range,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      location:
          json['location'] != null ? Location.fromJson(json['location']) : null,
      dropoffLocation:
          json['dropoff_location'] != null
              ? Location.fromJson(json['dropoff_location'])
              : null,
      preferences:
          json['preferences'] != null
              ? json['preferences'] as Map<String, dynamic>
              : null,
      drivingDistance: (json['driving_distance'] as num?)?.toDouble() ?? 0.0,
      status:
          json['status'] == 'active'
              ? DriverStatus.active
              : json['status'] == 'inactive'
              ? DriverStatus.inactive
              : DriverStatus.onTrip,
      acceptNewRequest: json['acceptNewRequest'] ?? 0,
      range: (json['range'] as num?)?.toDouble() ?? 5.0,
    );
  }

  /// **Method to convert to JSON**
  Map<String, dynamic> toJson() => _$DriverToJson(this);
  //Firestore
}

enum DriverStatus {
  @JsonValue("active")
  active,

  @JsonValue("inactive")
  inactive,

  @JsonValue("on_trip")
  onTrip,
}
