import 'package:json_annotation/json_annotation.dart';

part 'wallet.g.dart'; // This is the generated file

@JsonSerializable()
class Wallet {
  final int id;
  final int userId;
  double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a Wallet object from JSON
  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  // Method to convert Wallet object to JSON
  Map<String, dynamic> toJson() => _$WalletToJson(this);

  // Optional method to update wallet balance, can be used to add or subtract balance
  void updateBalance(double amount) {
    balance += amount;
  }
}
