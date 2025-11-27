class TripDetail {
  final int id;
  final DateTime timestamp;
  final double distance;
  final double price;
  final String paymentMethodName;
  final double commissionPercentage;
  final double commissionAmount;
  final double driverEarnings;
  final String status;

  TripDetail({
    required this.id,
    required this.timestamp,
    required this.distance,
    required this.price,
    required this.paymentMethodName,
    required this.commissionPercentage,
    required this.commissionAmount,
    required this.driverEarnings,
    required this.status,
  });

  factory TripDetail.fromJson(Map<String, dynamic> json) {
    return TripDetail(
      id: json['id'] as int,
      timestamp: DateTime.parse(json['created_at'] as String),
      distance: (json['distance'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      paymentMethodName: json['payment_method_name'] as String? ?? 'Unknown',
      commissionPercentage:
          (json['commission_percentage'] as num?)?.toDouble() ?? 0.0,
      commissionAmount: (json['commission_amount'] as num?)?.toDouble() ?? 0.0,
      driverEarnings: (json['driver_earnings'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'unknown',
    );
  }

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDistance {
    return '${distance.toStringAsFixed(1)} km';
  }

  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  String get formattedDriverEarnings {
    return '\$${driverEarnings.toStringAsFixed(2)}';
  }

  String get formattedCommission {
    return '\$${commissionAmount.toStringAsFixed(2)}';
  }
}
