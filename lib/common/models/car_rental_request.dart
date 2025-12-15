import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:json_annotation/json_annotation.dart';

part 'car_rental_request.g.dart';

@JsonSerializable()
class CarRentalRequest {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'car_rental_id')
  final int carRentalId;
  @JsonKey(name: 'car_rental')
  final ProvidedCarRental? carRental;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  @JsonKey(name: 'total_days')
  final int? totalDays;
  @JsonKey(name: 'total_price')
  final double? totalPrice;
  final String status;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CarRentalRequest({
    required this.id,
    required this.userId,
    required this.carRentalId,
    this.carRental,
    required this.startDate,
    required this.endDate,
    this.totalDays,
    this.totalPrice,
    this.status = 'pending',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CarRentalRequest.fromJson(Map<String, dynamic> json) =>
      _$CarRentalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CarRentalRequestToJson(this);
}
