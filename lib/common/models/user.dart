import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;

  final String? email;
  final String? phone;
  final String? sexe;
  final String? city;
  final String? role;
  final String? profile_image_path;
  final bool? banned;
  final DateTime? email_verified_at;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? password;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? remember_token;

  final DateTime? created_at;
  final DateTime? updated_at;

  User({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.sexe,
    this.city,
    this.role,
    this.profile_image_path,
    this.banned,
    this.email_verified_at,
    this.password,
    this.remember_token,
    this.created_at,
    this.updated_at,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
