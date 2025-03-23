import 'package:json_annotation/json_annotation.dart';

part 'wallet.g.dart';

@JsonSerializable()
class Wallet {
  final int? id;
  @JsonKey(name: 'user_id') // Ensures correct key mapping
  final int? userId;
  @JsonKey(fromJson: _stringToDouble, toJson: _doubleToString) // ✅ Fix here
  final double balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Wallet({
    this.id,
    this.userId,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  /// Convert string to double
  static double _stringToDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Convert double to string for JSON encoding
  static String _doubleToString(double value) => value.toString();

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);
  Map<String, dynamic> toJson() => _$WalletToJson(this);
}
