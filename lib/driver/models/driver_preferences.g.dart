// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DriverPreferences _$DriverPreferencesFromJson(Map<String, dynamic> json) =>
    DriverPreferences(
      intercityEnabled: json['intercity_enabled'] as bool? ?? true,
      drivioXEnabled: json['driviox_enabled'] as bool? ?? false,
      deliveriesEnabled: json['deliveries_enabled'] as bool? ?? false,
      smokingEnabled: json['smoking_enabled'] as bool? ?? false,
      teenRequestsEnabled: json['teen_requests_enabled'] as bool? ?? false,
      startTimeHour: (json['start_time_hour'] as num?)?.toInt() ?? 6,
      startTimeMinute: (json['start_time_minute'] as num?)?.toInt() ?? 0,
      endTimeHour: (json['end_time_hour'] as num?)?.toInt() ?? 22,
      endTimeMinute: (json['end_time_minute'] as num?)?.toInt() ?? 0,
      passengerWithPetsEnabled:
          json['passenger_with_pets_enabled'] as bool? ?? false,
    );

Map<String, dynamic> _$DriverPreferencesToJson(DriverPreferences instance) =>
    <String, dynamic>{
      'intercity_enabled': instance.intercityEnabled,
      'driviox_enabled': instance.drivioXEnabled,
      'deliveries_enabled': instance.deliveriesEnabled,
      'smoking_enabled': instance.smokingEnabled,
      'teen_requests_enabled': instance.teenRequestsEnabled,
      'start_time_hour': instance.startTimeHour,
      'start_time_minute': instance.startTimeMinute,
      'end_time_hour': instance.endTimeHour,
      'end_time_minute': instance.endTimeMinute,
      'passenger_with_pets_enabled': instance.passengerWithPetsEnabled,
    };
