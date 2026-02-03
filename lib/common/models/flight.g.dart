// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Flight _$FlightFromJson(Map<String, dynamic> json) => Flight(
  flightDate: json['flight_date'] as String?,
  flightStatus: json['flight_status'] as String?,
  departure:
      json['departure'] == null
          ? null
          : Departure.fromJson(json['departure'] as Map<String, dynamic>),
  arrival:
      json['arrival'] == null
          ? null
          : Arrival.fromJson(json['arrival'] as Map<String, dynamic>),
  airline:
      json['airline'] == null
          ? null
          : Airline.fromJson(json['airline'] as Map<String, dynamic>),
  flight:
      json['flight'] == null
          ? null
          : FlightInfo.fromJson(json['flight'] as Map<String, dynamic>),
  aircraft:
      json['aircraft'] == null
          ? null
          : Aircraft.fromJson(json['aircraft'] as Map<String, dynamic>),
  live:
      json['live'] == null
          ? null
          : Live.fromJson(json['live'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FlightToJson(Flight instance) => <String, dynamic>{
  'flight_date': instance.flightDate,
  'flight_status': instance.flightStatus,
  'departure': instance.departure,
  'arrival': instance.arrival,
  'airline': instance.airline,
  'flight': instance.flight,
  'aircraft': instance.aircraft,
  'live': instance.live,
};

Departure _$DepartureFromJson(Map<String, dynamic> json) => Departure(
  airport: json['airport'] as String?,
  timezone: json['timezone'] as String?,
  iata: json['iata'] as String?,
  icao: json['icao'] as String?,
  terminal: json['terminal'] as String?,
  gate: json['gate'] as String?,
  delay: (json['delay'] as num?)?.toInt(),
  scheduled: json['scheduled'] as String?,
  estimated: json['estimated'] as String?,
  actual: json['actual'] as String?,
  estimatedRunway: json['estimated_runway'] as String?,
  actualRunway: json['actual_runway'] as String?,
);

Map<String, dynamic> _$DepartureToJson(Departure instance) => <String, dynamic>{
  'airport': instance.airport,
  'timezone': instance.timezone,
  'iata': instance.iata,
  'icao': instance.icao,
  'terminal': instance.terminal,
  'gate': instance.gate,
  'delay': instance.delay,
  'scheduled': instance.scheduled,
  'estimated': instance.estimated,
  'actual': instance.actual,
  'estimated_runway': instance.estimatedRunway,
  'actual_runway': instance.actualRunway,
};

Arrival _$ArrivalFromJson(Map<String, dynamic> json) => Arrival(
  airport: json['airport'] as String?,
  timezone: json['timezone'] as String?,
  iata: json['iata'] as String?,
  icao: json['icao'] as String?,
  terminal: json['terminal'] as String?,
  gate: json['gate'] as String?,
  baggage: json['baggage'] as String?,
  delay: (json['delay'] as num?)?.toInt(),
  scheduled: json['scheduled'] as String?,
  estimated: json['estimated'] as String?,
  actual: json['actual'] as String?,
  estimatedRunway: json['estimated_runway'] as String?,
  actualRunway: json['actual_runway'] as String?,
);

Map<String, dynamic> _$ArrivalToJson(Arrival instance) => <String, dynamic>{
  'airport': instance.airport,
  'timezone': instance.timezone,
  'iata': instance.iata,
  'icao': instance.icao,
  'terminal': instance.terminal,
  'gate': instance.gate,
  'baggage': instance.baggage,
  'delay': instance.delay,
  'scheduled': instance.scheduled,
  'estimated': instance.estimated,
  'actual': instance.actual,
  'estimated_runway': instance.estimatedRunway,
  'actual_runway': instance.actualRunway,
};

Airline _$AirlineFromJson(Map<String, dynamic> json) => Airline(
  name: json['name'] as String?,
  iata: json['iata'] as String?,
  icao: json['icao'] as String?,
);

Map<String, dynamic> _$AirlineToJson(Airline instance) => <String, dynamic>{
  'name': instance.name,
  'iata': instance.iata,
  'icao': instance.icao,
};

FlightInfo _$FlightInfoFromJson(Map<String, dynamic> json) => FlightInfo(
  number: json['number'] as String?,
  iata: json['iata'] as String?,
  icao: json['icao'] as String?,
  codeshared:
      json['codeshared'] == null
          ? null
          : Codeshared.fromJson(json['codeshared'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FlightInfoToJson(FlightInfo instance) =>
    <String, dynamic>{
      'number': instance.number,
      'iata': instance.iata,
      'icao': instance.icao,
      'codeshared': instance.codeshared,
    };

Codeshared _$CodesharedFromJson(Map<String, dynamic> json) => Codeshared(
  airlineName: json['airline_name'] as String?,
  airlineIata: json['airline_iata'] as String?,
  airlineIcao: json['airline_icao'] as String?,
  flightNumber: json['flight_number'] as String?,
  flightIata: json['flight_iata'] as String?,
  flightIcao: json['flight_icao'] as String?,
);

Map<String, dynamic> _$CodesharedToJson(Codeshared instance) =>
    <String, dynamic>{
      'airline_name': instance.airlineName,
      'airline_iata': instance.airlineIata,
      'airline_icao': instance.airlineIcao,
      'flight_number': instance.flightNumber,
      'flight_iata': instance.flightIata,
      'flight_icao': instance.flightIcao,
    };

Aircraft _$AircraftFromJson(Map<String, dynamic> json) => Aircraft(
  registration: json['registration'] as String?,
  iata: json['iata'] as String?,
  icao: json['icao'] as String?,
  icao24: json['icao24'] as String?,
);

Map<String, dynamic> _$AircraftToJson(Aircraft instance) => <String, dynamic>{
  'registration': instance.registration,
  'iata': instance.iata,
  'icao': instance.icao,
  'icao24': instance.icao24,
};

Live _$LiveFromJson(Map<String, dynamic> json) => Live(
  updated: json['updated'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  altitude: (json['altitude'] as num?)?.toDouble(),
  direction: (json['direction'] as num?)?.toDouble(),
  speedHorizontal: (json['speed_horizontal'] as num?)?.toDouble(),
  speedVertical: (json['speed_vertical'] as num?)?.toDouble(),
  isGround: json['is_ground'] as bool?,
);

Map<String, dynamic> _$LiveToJson(Live instance) => <String, dynamic>{
  'updated': instance.updated,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'altitude': instance.altitude,
  'direction': instance.direction,
  'speed_horizontal': instance.speedHorizontal,
  'speed_vertical': instance.speedVertical,
  'is_ground': instance.isGround,
};
