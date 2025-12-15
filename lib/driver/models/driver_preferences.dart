import 'package:json_annotation/json_annotation.dart';

part 'driver_preferences.g.dart';

@JsonSerializable()
class DriverPreferences {
  // Services
  @JsonKey(name: 'intercity_enabled')
  final bool intercityEnabled;

  @JsonKey(name: 'driviox_enabled')
  final bool drivioXEnabled;

  @JsonKey(name: 'deliveries_enabled')
  final bool deliveriesEnabled;

  @JsonKey(name: 'smoking_enabled')
  final bool smokingEnabled;

  // Trip filters
  @JsonKey(name: 'teen_requests_enabled')
  final bool teenRequestsEnabled;

  @JsonKey(name: 'start_time_hour')
  final int startTimeHour;

  @JsonKey(name: 'start_time_minute')
  final int startTimeMinute;

  @JsonKey(name: 'end_time_hour')
  final int endTimeHour;

  @JsonKey(name: 'end_time_minute')
  final int endTimeMinute;

  @JsonKey(name: 'passenger_with_pets_enabled')
  final bool passengerWithPetsEnabled;

  const DriverPreferences({
    this.intercityEnabled = true,
    this.drivioXEnabled = false,
    this.deliveriesEnabled = false,
    this.smokingEnabled = false,
    this.teenRequestsEnabled = false,
    this.startTimeHour = 6,
    this.startTimeMinute = 0,
    this.endTimeHour = 22,
    this.endTimeMinute = 0,
    this.passengerWithPetsEnabled = false,
  });

  factory DriverPreferences.fromJson(Map<String, dynamic> json) =>
      _$DriverPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$DriverPreferencesToJson(this);

  DriverPreferences copyWith({
    bool? intercityEnabled,
    bool? drivioXEnabled,
    bool? deliveriesEnabled,
    bool? smokingEnabled,
    bool? teenRequestsEnabled,
    int? startTimeHour,
    int? startTimeMinute,
    int? endTimeHour,
    int? endTimeMinute,
    bool? passengerWithPetsEnabled,
  }) {
    return DriverPreferences(
      intercityEnabled: intercityEnabled ?? this.intercityEnabled,
      drivioXEnabled: drivioXEnabled ?? this.drivioXEnabled,
      deliveriesEnabled: deliveriesEnabled ?? this.deliveriesEnabled,
      smokingEnabled: smokingEnabled ?? this.smokingEnabled,
      teenRequestsEnabled: teenRequestsEnabled ?? this.teenRequestsEnabled,
      startTimeHour: startTimeHour ?? this.startTimeHour,
      startTimeMinute: startTimeMinute ?? this.startTimeMinute,
      endTimeHour: endTimeHour ?? this.endTimeHour,
      endTimeMinute: endTimeMinute ?? this.endTimeMinute,
      passengerWithPetsEnabled:
          passengerWithPetsEnabled ?? this.passengerWithPetsEnabled,
    );
  }
}
