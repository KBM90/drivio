import 'package:json_annotation/json_annotation.dart';

part 'user_payment_method.g.dart';

@JsonSerializable()
class UserPaymentMethod {
  final int id;

  @JsonKey(name: 'user_id')
  final int userId;

  @JsonKey(name: 'payment_method_id')
  final int paymentMethodId;

  final Map<String, dynamic>? details;

  @JsonKey(name: 'is_default')
  final bool isDefault;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  UserPaymentMethod({
    required this.id,
    required this.userId,
    required this.paymentMethodId,
    this.details,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory UserPaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$UserPaymentMethodFromJson(json);

  Map<String, dynamic> toJson() => _$UserPaymentMethodToJson(this);
}
