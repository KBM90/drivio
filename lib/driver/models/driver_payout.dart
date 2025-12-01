import 'package:intl/intl.dart';

class DriverPayout {
  final int id;
  final int driverId;
  final double payoutAmount;
  final double remainingBalance;
  final String? paymentMethod;
  final String payoutStatus;
  final String? transactionId;
  final DateTime? payoutDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverPayout({
    required this.id,
    required this.driverId,
    required this.payoutAmount,
    required this.remainingBalance,
    this.paymentMethod,
    required this.payoutStatus,
    this.transactionId,
    this.payoutDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DriverPayout.fromJson(Map<String, dynamic> json) {
    return DriverPayout(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      payoutAmount: (json['payout_amount'] as num).toDouble(),
      remainingBalance: (json['remaining_balance'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      payoutStatus: json['payout_status'] as String? ?? 'pending',
      transactionId: json['transaction_id'] as String?,
      payoutDate:
          json['payout_date'] != null
              ? DateTime.parse(json['payout_date'] as String)
              : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get formattedAmount => '\$${payoutAmount.toStringAsFixed(2)}';

  String get formattedDate =>
      payoutDate != null
          ? DateFormat('MMM d, yyyy').format(payoutDate!)
          : 'Pending';

  String get statusLabel {
    switch (payoutStatus.toLowerCase()) {
      case 'processed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      default:
        return payoutStatus;
    }
  }
}
