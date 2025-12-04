class VehicleDocument {
  final int id;
  final int vehicleId;
  final String documentName;
  final String documentType;
  final DateTime expiringDate;
  final int imageId;
  final bool isExpired;
  final bool isVerified;
  final String? imagePath; // Joined from document_images
  final Map<String, dynamic>? metadata; // Store type-specific fields

  VehicleDocument({
    required this.id,
    required this.vehicleId,
    required this.documentName,
    required this.documentType,
    required this.expiringDate,
    required this.imageId,
    required this.isExpired,
    this.isVerified = false,
    this.imagePath,
    this.metadata,
  });

  factory VehicleDocument.fromJson(Map<String, dynamic> json) {
    return VehicleDocument(
      id: json['id'] as int,
      vehicleId: json['vehicle_id'] as int,
      documentName: json['document_name'] as String,
      documentType: json['document_type'] as String,
      expiringDate: DateTime.parse(json['expiring_date'] as String),
      imageId: json['image_id'] as int,
      isExpired: json['is_expired'] as bool,
      isVerified: json['is_verified'] as bool? ?? false,
      imagePath: json['document_images']?['image_path'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'document_name': documentName,
      'document_type': documentType,
      'expiring_date': expiringDate.toIso8601String(),
      'image_id': imageId,
      'is_expired': isExpired,
      'is_verified': isVerified,
      'metadata': metadata,
    };
  }
}
