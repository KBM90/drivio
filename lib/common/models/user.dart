import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? sexe;
  final String? city;
  final String role;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? password;

  final String? profile_image_path;
  final bool banned;
  final DateTime? email_verified_at;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? remember_token;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.sexe,
    this.city,
    this.role = 'user',
    this.password,
    this.profile_image_path,
    this.banned = false,
    this.email_verified_at,
    this.remember_token,
  });

  // Corrected copyWith method
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? sexe,
    String? city,
    String? role,
    String? password,
    String? profile_image_path,
    bool? banned,
    DateTime? email_verified_at,
    String? remember_token,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone, // Fixed phone initialization
      sexe: sexe ?? this.sexe,
      city: city ?? this.city,
      role: role ?? this.role,
      password: password ?? this.password,
      profile_image_path: profile_image_path ?? this.profile_image_path,
      banned: banned ?? this.banned,
      email_verified_at: email_verified_at ?? this.email_verified_at,
      remember_token: remember_token ?? this.remember_token,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
