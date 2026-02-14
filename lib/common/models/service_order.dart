import 'package:json_annotation/json_annotation.dart';
import 'package:drivio_app/common/models/location.dart';

part 'service_order.g.dart';

@JsonSerializable(explicitToJson: true)
class ServiceOrder {
  final int id;

  @JsonKey(name: 'service_id')
  final int? serviceId; // Nullable for custom orders

  @JsonKey(name: 'requester_user_id')
  final int requesterUserId;

  @JsonKey(name: 'provider_id')
  final int? providerId; // Nullable for custom orders

  // Custom order fields
  @JsonKey(name: 'custom_service_name')
  final String? customServiceName;

  final String? category;

  // Order details
  final int quantity;
  final String? notes;

  @JsonKey(name: 'preferred_contact_method')
  final String preferredContactMethod; // 'phone', 'whatsapp', 'sms'

  // Requester info (denormalized for quick access)
  @JsonKey(name: 'requester_name')
  final String requesterName;

  @JsonKey(name: 'requester_phone')
  final String requesterPhone;

  @JsonKey(
    name: 'requester_location',
    fromJson: _locationFromPostGIS,
    toJson: _locationToPostGIS,
  )
  final Location? requesterLocation;

  // Order status
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Optional: Service details (when joined)
  @JsonKey(
    name: 'provided_services',
    includeFromJson: true,
    includeToJson: false,
  )
  final Map<String, dynamic>? serviceDetails;

  ServiceOrder({
    required this.id,
    this.serviceId,
    required this.requesterUserId,
    this.providerId,
    this.customServiceName,
    this.category,
    required this.quantity,
    this.notes,
    required this.preferredContactMethod,
    required this.requesterName,
    required this.requesterPhone,
    this.requesterLocation,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.serviceDetails,
  });

  factory ServiceOrder.fromJson(Map<String, dynamic> json) =>
      _$ServiceOrderFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceOrderToJson(this);

  // Check if this is a custom order
  bool get isCustomOrder => serviceId == null && customServiceName != null;

  // Get display name (either from service or custom name)
  String get displayName =>
      customServiceName ?? serviceName ?? 'Unknown Service';

  // Helper to get service name from joined data
  String? get serviceName => serviceDetails?['name'] as String?;

  // Helper to get service price from joined data
  double? get servicePrice {
    final price = serviceDetails?['price'];
    return price != null ? (price as num).toDouble() : null;
  }

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
    return 'ServiceOrder(id: $id, serviceId: $serviceId, customServiceName: $customServiceName, '
        'category: $category, requesterUserId: $requesterUserId, status: $status, quantity: $quantity, createdAt: $createdAt)';
  }
}
