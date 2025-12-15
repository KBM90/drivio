import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/models/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'car_renter.g.dart';

@JsonSerializable()
class CarRenter {
  @JsonKey(fromJson: _idFromJson)
  final int id;
  @JsonKey(name: 'user_id', fromJson: _userIdFromJson)
  final int userId;
  final User? user;

  static int _idFromJson(dynamic value) {
    if (value == null) return 0;
    return (value as num).toInt();
  }

  static int _userIdFromJson(dynamic value) {
    if (value == null) return 0;
    return (value as num).toInt();
  }

  @JsonKey(name: 'business_name')
  final String? businessName;
  final Location? location;
  final String? city;
  final double? rating;
  @JsonKey(name: 'total_cars')
  final int? totalCars;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CarRenter({
    required this.id,
    required this.userId,
    this.user,
    this.businessName,
    this.location,
    this.city,
    this.rating,
    this.totalCars,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  factory CarRenter.fromJson(Map<String, dynamic> json) =>
      _$CarRenterFromJson(json);

  Map<String, dynamic> toJson() => _$CarRenterToJson(this);
}
