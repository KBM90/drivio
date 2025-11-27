class EarningsData {
  final double totalEarnings;
  final double cashEarnings;
  final double bankTransferEarnings;
  final double otherEarnings;
  final int totalTrips;
  final int onlineHours;
  final int onlineMinutes;
  final int points;
  final DateTime? nextPayoutDate;
  final double nextPayoutAmount;
  final DateTime periodStart;
  final DateTime periodEnd;

  EarningsData({
    required this.totalEarnings,
    required this.cashEarnings,
    required this.bankTransferEarnings,
    required this.otherEarnings,
    required this.totalTrips,
    required this.onlineHours,
    required this.onlineMinutes,
    required this.points,
    this.nextPayoutDate,
    required this.nextPayoutAmount,
    required this.periodStart,
    required this.periodEnd,
  });

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    return EarningsData(
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      cashEarnings: (json['cash_earnings'] as num?)?.toDouble() ?? 0.0,
      bankTransferEarnings:
          (json['bank_transfer_earnings'] as num?)?.toDouble() ?? 0.0,
      otherEarnings: (json['other_earnings'] as num?)?.toDouble() ?? 0.0,
      totalTrips: (json['total_trips'] as int?) ?? 0,
      onlineHours:
          (json['online_hours'] as int?) ??
          ((json['total_online_minutes'] as int?) ?? 0) ~/ 60,
      onlineMinutes:
          (json['online_minutes'] as int?) ??
          ((json['total_online_minutes'] as int?) ?? 0) % 60,
      points: (json['points'] as int?) ?? 0,
      nextPayoutDate:
          json['next_payout_date'] != null
              ? DateTime.parse(json['next_payout_date'])
              : null,
      nextPayoutAmount: (json['next_payout_amount'] as num?)?.toDouble() ?? 0.0,
      periodStart: DateTime.parse(
        json['period_start'] ?? DateTime.now().toIso8601String(),
      ),
      periodEnd: DateTime.parse(
        json['period_end'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'cash_earnings': cashEarnings,
      'bank_transfer_earnings': bankTransferEarnings,
      'other_earnings': otherEarnings,
      'total_trips': totalTrips,
      'online_hours': onlineHours,
      'online_minutes': onlineMinutes,
      'points': points,
      'next_payout_date': nextPayoutDate?.toIso8601String(),
      'next_payout_amount': nextPayoutAmount,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
    };
  }

  String get formattedOnlineTime {
    return '$onlineHours h ${onlineMinutes} m';
  }

  String get formattedTotalBalance {
    return '\$${totalEarnings.toStringAsFixed(2)}';
  }

  String get formattedCashEarnings {
    return '\$${cashEarnings.toStringAsFixed(2)}';
  }

  String get formattedBankTransferEarnings {
    return '\$${bankTransferEarnings.toStringAsFixed(2)}';
  }

  String get formattedOtherEarnings {
    return '\$${otherEarnings.toStringAsFixed(2)}';
  }

  String get formattedNextPayoutAmount {
    return '\$${nextPayoutAmount.toStringAsFixed(2)}';
  }

  bool get hasCashEarnings => cashEarnings > 0;
  bool get hasBankTransferEarnings => bankTransferEarnings > 0;
  bool get hasOtherEarnings => otherEarnings > 0;
}
