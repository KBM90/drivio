import 'package:drivio_app/common/models/ride_request.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'rating.g.dart';

@JsonSerializable()
class Rating {
  final int id;

  @JsonKey(name: 'rated_user')
  final int ratedUser;
  @JsonKey(name: 'rated_by')
  final int ratedBy;
  final int rating;
  final String? review;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Optional relations
  final RideRequest? rideRequest;
  final User? ratedByUser;

  Rating({
    required this.id,
    required this.ratedUser,
    required this.ratedBy,
    this.rating = 5,
    this.review,
    this.createdAt,
    this.updatedAt,
    this.rideRequest,
    this.ratedByUser,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);
  Map<String, dynamic> toJson() => _$RatingToJson(this);
}
