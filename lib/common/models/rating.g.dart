// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Rating _$RatingFromJson(Map<String, dynamic> json) => Rating(
  id: (json['id'] as num).toInt(),
  rideRequestId: (json['ride_request_id'] as num).toInt(),
  ratedUser: (json['rated_user'] as num).toInt(),
  ratedBy: (json['rated_by'] as num).toInt(),
  rating: (json['rating'] as num?)?.toInt() ?? 5,
  review: json['review'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  rideRequest:
      json['rideRequest'] == null
          ? null
          : RideRequest.fromJson(json['rideRequest'] as Map<String, dynamic>),
  ratedByUser:
      json['ratedByUser'] == null
          ? null
          : User.fromJson(json['ratedByUser'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RatingToJson(Rating instance) => <String, dynamic>{
  'id': instance.id,
  'ride_request_id': instance.rideRequestId,
  'rated_user': instance.ratedUser,
  'rated_by': instance.ratedBy,
  'rating': instance.rating,
  'review': instance.review,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'rideRequest': instance.rideRequest,
  'ratedByUser': instance.ratedByUser,
};
