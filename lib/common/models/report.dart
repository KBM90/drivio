import 'package:json_annotation/json_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  final int? id;

  @JsonKey(name: 'reported_by')
  final int reportedBy;

  @JsonKey(name: 'reported_user')
  final int reportedUser;

  final String reason;
  final String? details;
  final String status;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Report({
    this.id,
    required this.reportedBy,
    required this.reportedUser,
    required this.reason,
    this.details,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);

  Map<String, dynamic> toJson() => _$ReportToJson(this);

  // Helper method for creating a new report (without id and timestamps)
  Map<String, dynamic> toCreateJson() {
    return {
      'reported_by': reportedBy,
      'reported_user': reportedUser,
      'reason': reason,
      if (details != null && details!.isNotEmpty) 'details': details,
      'status': status,
    };
  }
}

// Report reason constants
class ReportReasons {
  // Driver-specific reasons (when reporting passengers)
  static const driverReasons = [
    ReportReason(
      value: 'rude_behavior',
      label: 'Rude or Disrespectful Behavior',
    ),
    ReportReason(value: 'no_show', label: 'Passenger Didn\'t Show Up'),
    ReportReason(
      value: 'drunk_or_disorderly',
      label: 'Intoxicated or Disorderly',
    ),
    ReportReason(
      value: 'harassment',
      label: 'Harassment or Inappropriate Conduct',
    ),
    ReportReason(value: 'discrimination', label: 'Discriminatory Behavior'),
    ReportReason(value: 'property_damage', label: 'Damage to Vehicle'),
    ReportReason(value: 'payment_issue', label: 'Payment Problems'),
    ReportReason(value: 'ride_cancellation', label: 'Last-Minute Cancellation'),
    ReportReason(value: 'unfair_rating', label: 'Unfair Rating Given'),
    ReportReason(value: 'other', label: 'Other Issues'),
  ];

  // Passenger-specific reasons (when reporting drivers)
  static const passengerReasons = [
    ReportReason(
      value: 'reckless_driving',
      label: 'Unsafe or Reckless Driving',
    ),
    ReportReason(value: 'overcharging', label: 'Charging More Than Agreed'),
    ReportReason(
      value: 'rude_behavior',
      label: 'Rude or Disrespectful Behavior',
    ),
    ReportReason(value: 'vehicle_condition', label: 'Poor Vehicle Condition'),
    ReportReason(value: 'route_issue', label: 'Wrong or Inefficient Route'),
    ReportReason(value: 'unsafe_experience', label: 'Felt Unsafe During Ride'),
    ReportReason(
      value: 'ride_cancellation',
      label: 'Driver Cancelled Unexpectedly',
    ),
    ReportReason(value: 'payment_issue', label: 'Payment Disputes'),
    ReportReason(
      value: 'harassment',
      label: 'Harassment or Inappropriate Conduct',
    ),
    ReportReason(value: 'discrimination', label: 'Discriminatory Behavior'),
    ReportReason(value: 'unfair_rating', label: 'Unfair Rating Given'),
    ReportReason(value: 'other', label: 'Other Issues'),
  ];
}

class ReportReason {
  final String value;
  final String label;

  const ReportReason({required this.value, required this.label});
}
