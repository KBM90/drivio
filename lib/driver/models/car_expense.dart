import 'package:json_annotation/json_annotation.dart';

part 'car_expense.g.dart';

enum ExpenseType {
  fuel,
  maintenance,
  insurance,
  registration,
  depreciation,
  other,
}

@JsonSerializable()
class CarExpense {
  final int? id;
  @JsonKey(name: 'driver_id')
  final int driverId;
  @JsonKey(name: 'expense_type')
  final String expenseType;
  final double amount;
  final String? description;
  @JsonKey(name: 'expense_date')
  final DateTime expenseDate;
  @JsonKey(name: 'odometer_reading')
  final int? odometerReading;
  @JsonKey(name: 'fuel_liters')
  final double? fuelLiters;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CarExpense({
    this.id,
    required this.driverId,
    required this.expenseType,
    required this.amount,
    this.description,
    required this.expenseDate,
    this.odometerReading,
    this.fuelLiters,
    this.distanceKm,
    this.createdAt,
    this.updatedAt,
  });

  factory CarExpense.fromJson(Map<String, dynamic> json) =>
      _$CarExpenseFromJson(json);

  Map<String, dynamic> toJson() => _$CarExpenseToJson(this);

  // Helper method to convert to database format
  Map<String, dynamic> toDatabase() {
    return {
      if (id != null) 'id': id,
      'driver_id': driverId,
      'expense_type': expenseType,
      'amount': amount,
      if (description != null) 'description': description,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      if (odometerReading != null) 'odometer_reading': odometerReading,
      if (fuelLiters != null) 'fuel_liters': fuelLiters,
      if (distanceKm != null) 'distance_km': distanceKm,
    };
  }

  // Calculate fuel consumption (L/100km)
  double? get fuelConsumption {
    if (fuelLiters != null && distanceKm != null && distanceKm! > 0) {
      return (fuelLiters! / distanceKm!) * 100;
    }
    return null;
  }

  // Calculate cost per kilometer
  double? get costPerKm {
    if (distanceKm != null && distanceKm! > 0) {
      return amount / distanceKm!;
    }
    return null;
  }

  // Get expense type icon
  String get expenseTypeIcon {
    switch (expenseType) {
      case 'fuel':
        return '⛽';
      case 'maintenance':
        return '🔧';
      case 'insurance':
        return '🛡️';
      case 'registration':
        return '📋';
      case 'depreciation':
        return '📉';
      default:
        return '💰';
    }
  }

  // Get expense type display name
  String get expenseTypeDisplayName {
    switch (expenseType) {
      case 'fuel':
        return 'Fuel';
      case 'maintenance':
        return 'Maintenance';
      case 'insurance':
        return 'Insurance';
      case 'registration':
        return 'Registration';
      case 'depreciation':
        return 'Depreciation';
      default:
        return 'Other';
    }
  }

  // Format amount as currency
  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Format date
  String get formattedDate {
    return '${expenseDate.day}/${expenseDate.month}/${expenseDate.year}';
  }

  // Copy with method for immutability
  CarExpense copyWith({
    int? id,
    int? driverId,
    String? expenseType,
    double? amount,
    String? description,
    DateTime? expenseDate,
    int? odometerReading,
    double? fuelLiters,
    double? distanceKm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CarExpense(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      expenseType: expenseType ?? this.expenseType,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      odometerReading: odometerReading ?? this.odometerReading,
      fuelLiters: fuelLiters ?? this.fuelLiters,
      distanceKm: distanceKm ?? this.distanceKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
