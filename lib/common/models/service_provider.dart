import 'package:drivio_app/common/models/location.dart';

class ServiceProvider {
  final int id;
  final int userId;
  final String businessName;
  final String providerType;
  final String? address;
  final Location? location;
  final double rating;
  final bool isVerified;
  final DateTime createdAt;

  ServiceProvider({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.providerType,
    this.address,
    this.location,
    required this.rating,
    required this.isVerified,
    required this.createdAt,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    Location? loc;
    if (json['location'] != null) {
      if (json['location'] is Map<String, dynamic>) {
        final coords = json['location']['coordinates'] as List;
        loc = Location(latitude: coords[1], longitude: coords[0]);
      }
    }

    return ServiceProvider(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      businessName: json['business_name'] as String,
      providerType: json['provider_type'] as String,
      address: json['address'] as String?,
      location: loc,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
