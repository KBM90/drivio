import 'package:json_annotation/json_annotation.dart';

part 'driver_document.g.dart';

@JsonSerializable()
class DriverDocument {
  final int id;
  @JsonKey(name: 'driver_id')
  final int driverId;
  final String type; // 'Driving License', 'ID Card', 'Passport'
  final String number;
  @JsonKey(name: 'expiring_date')
  final DateTime expiringDate;
  @JsonKey(name: 'image_id')
  final int? imageId;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Optional: image path if joined with document_images table
  @JsonKey(name: 'image_path')
  final String? imagePath;

  DriverDocument({
    required this.id,
    required this.driverId,
    required this.type,
    required this.number,
    required this.expiringDate,
    this.imageId,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
    this.imagePath,
  });

  factory DriverDocument.fromJson(Map<String, dynamic> json) =>
      _$DriverDocumentFromJson(json);

  Map<String, dynamic> toJson() => _$DriverDocumentToJson(this);

  // Helper method to check if document is expired
  bool get isExpired => expiringDate.isBefore(DateTime.now());

  // Helper method to get days until expiration
  int get daysUntilExpiration => expiringDate.difference(DateTime.now()).inDays;

  // Copy with method for updates
  DriverDocument copyWith({
    int? id,
    int? driverId,
    String? type,
    String? number,
    DateTime? expiringDate,
    int? imageId,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imagePath,
  }) {
    return DriverDocument(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      type: type ?? this.type,
      number: number ?? this.number,
      expiringDate: expiringDate ?? this.expiringDate,
      imageId: imageId ?? this.imageId,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
