// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) => Wallet(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  balance: (json['balance'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'balance': instance.balance,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
