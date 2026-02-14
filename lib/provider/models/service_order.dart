enum ServiceOrderStatus { pending, confirmed, completed, cancelled }

class ServiceOrder {
  final int id;
  final int? serviceId; // Nullable for custom orders
  final int requesterUserId;
  final int? providerId; // Nullable for custom orders
  final String? customServiceName; // For custom orders
  final String? category; // For custom orders
  final int quantity;
  final String? notes;
  final String preferredContactMethod;
  final String requesterName;
  final String requesterPhone;
  // requester_location is geometry in DB, representing as simple Map or similar for now if needed,
  // or just skipping if not strictly required for display list.
  // For frontend list, we usually don't need raw geometry.
  final ServiceOrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceOrder({
    required this.id,
    this.serviceId,
    required this.requesterUserId,
    this.providerId,
    this.customServiceName,
    this.category,
    this.quantity = 1,
    this.notes,
    this.preferredContactMethod = 'phone',
    required this.requesterName,
    required this.requesterPhone,
    this.status = ServiceOrderStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    return ServiceOrder(
      id: json['id'] as int,
      serviceId: json['service_id'] as int?,
      requesterUserId: json['requester_user_id'] as int,
      providerId: json['provider_id'] as int?,
      customServiceName: json['custom_service_name'] as String?,
      category: json['category'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      notes: json['notes'] as String?,
      preferredContactMethod:
          json['preferred_contact_method'] as String? ?? 'phone',
      requesterName: json['requester_name'] as String,
      requesterPhone: json['requester_phone'] as String,
      status: ServiceOrderStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => ServiceOrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  // Check if this is a custom order
  bool get isCustomOrder => serviceId == null && customServiceName != null;
}
