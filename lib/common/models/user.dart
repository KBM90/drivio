import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? countryCode;
  final String? sexe;
  final String? city;
  final String? role;

  @JsonKey(name: 'profile_image_path')
  final String? profileImagePath;

  final bool banned;

  @JsonKey(name: 'email_verified_at')
  final DateTime? emailVerifiedAt;

  @JsonKey(name: 'remember_token')
  final String? rememberToken;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'user_id')
  final String? userId; // UUID from auth.users

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.countryCode,
    this.sexe,
    this.city,
    required this.role,
    this.profileImagePath,
    this.banned = false,
    this.emailVerifiedAt,
    this.rememberToken,
    this.createdAt,
    this.updatedAt,
    this.userId,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
