// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'car_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarExpense _$CarExpenseFromJson(Map<String, dynamic> json) => CarExpense(
  id: (json['id'] as num?)?.toInt(),
  driverId: (json['driver_id'] as num).toInt(),
  expenseType: json['expense_type'] as String,
  amount: (json['amount'] as num).toDouble(),
  description: json['description'] as String?,
  expenseDate: DateTime.parse(json['expense_date'] as String),
  odometerReading: (json['odometer_reading'] as num?)?.toInt(),
  fuelLiters: (json['fuel_liters'] as num?)?.toDouble(),
  distanceKm: (json['distance_km'] as num?)?.toDouble(),
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$CarExpenseToJson(CarExpense instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver_id': instance.driverId,
      'expense_type': instance.expenseType,
      'amount': instance.amount,
      'description': instance.description,
      'expense_date': instance.expenseDate.toIso8601String(),
      'odometer_reading': instance.odometerReading,
      'fuel_liters': instance.fuelLiters,
      'distance_km': instance.distanceKm,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
