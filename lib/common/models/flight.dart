import 'package:json_annotation/json_annotation.dart';

part 'flight.g.dart';

@JsonSerializable()
class Flight {
  @JsonKey(name: 'flight_date')
  final String? flightDate;

  @JsonKey(name: 'flight_status')
  final String? flightStatus;

  final Departure? departure;
  final Arrival? arrival;
  final Airline? airline;
  final FlightInfo? flight;
  final Aircraft? aircraft;
  final Live? live;

  Flight({
    this.flightDate,
    this.flightStatus,
    this.departure,
    this.arrival,
    this.airline,
    this.flight,
    this.aircraft,
    this.live,
  });

  factory Flight.fromJson(Map<String, dynamic> json) => _$FlightFromJson(json);
  Map<String, dynamic> toJson() => _$FlightToJson(this);

  // Helper getters for UI
  String get statusDisplay => flightStatus ?? 'Unknown';
  String get flightNumber => flight?.number ?? 'N/A';
  String get airlineName => airline?.name ?? 'Unknown Airline';
  String get departureAirport => departure?.airport ?? 'N/A';
  String get arrivalAirport => arrival?.airport ?? 'N/A';
  String get departureTime => departure?.scheduled ?? 'N/A';
  String get arrivalTime => arrival?.scheduled ?? 'N/A';

  bool get isDelayed => flightStatus?.toLowerCase() == 'delayed';
  bool get isActive => flightStatus?.toLowerCase() == 'active';
  bool get isLanded => flightStatus?.toLowerCase() == 'landed';
  bool get isCancelled => flightStatus?.toLowerCase() == 'cancelled';
  bool get isScheduled => flightStatus?.toLowerCase() == 'scheduled';
}

@JsonSerializable()
class Departure {
  final String? airport;
  final String? timezone;
  final String? iata;
  final String? icao;
  final String? terminal;
  final String? gate;
  final int? delay;
  final String? scheduled;
  final String? estimated;
  final String? actual;

  @JsonKey(name: 'estimated_runway')
  final String? estimatedRunway;

  @JsonKey(name: 'actual_runway')
  final String? actualRunway;

  Departure({
    this.airport,
    this.timezone,
    this.iata,
    this.icao,
    this.terminal,
    this.gate,
    this.delay,
    this.scheduled,
    this.estimated,
    this.actual,
    this.estimatedRunway,
    this.actualRunway,
  });

  factory Departure.fromJson(Map<String, dynamic> json) =>
      _$DepartureFromJson(json);
  Map<String, dynamic> toJson() => _$DepartureToJson(this);
}

@JsonSerializable()
class Arrival {
  final String? airport;
  final String? timezone;
  final String? iata;
  final String? icao;
  final String? terminal;
  final String? gate;
  final String? baggage;
  final int? delay;
  final String? scheduled;
  final String? estimated;
  final String? actual;

  @JsonKey(name: 'estimated_runway')
  final String? estimatedRunway;

  @JsonKey(name: 'actual_runway')
  final String? actualRunway;

  Arrival({
    this.airport,
    this.timezone,
    this.iata,
    this.icao,
    this.terminal,
    this.gate,
    this.baggage,
    this.delay,
    this.scheduled,
    this.estimated,
    this.actual,
    this.estimatedRunway,
    this.actualRunway,
  });

  factory Arrival.fromJson(Map<String, dynamic> json) =>
      _$ArrivalFromJson(json);
  Map<String, dynamic> toJson() => _$ArrivalToJson(this);
}

@JsonSerializable()
class Airline {
  final String? name;
  final String? iata;
  final String? icao;

  Airline({this.name, this.iata, this.icao});

  factory Airline.fromJson(Map<String, dynamic> json) =>
      _$AirlineFromJson(json);
  Map<String, dynamic> toJson() => _$AirlineToJson(this);
}

@JsonSerializable()
class FlightInfo {
  final String? number;
  final String? iata;
  final String? icao;
  final Codeshared? codeshared;

  FlightInfo({this.number, this.iata, this.icao, this.codeshared});

  factory FlightInfo.fromJson(Map<String, dynamic> json) =>
      _$FlightInfoFromJson(json);
  Map<String, dynamic> toJson() => _$FlightInfoToJson(this);
}

@JsonSerializable()
class Codeshared {
  @JsonKey(name: 'airline_name')
  final String? airlineName;

  @JsonKey(name: 'airline_iata')
  final String? airlineIata;

  @JsonKey(name: 'airline_icao')
  final String? airlineIcao;

  @JsonKey(name: 'flight_number')
  final String? flightNumber;

  @JsonKey(name: 'flight_iata')
  final String? flightIata;

  @JsonKey(name: 'flight_icao')
  final String? flightIcao;

  Codeshared({
    this.airlineName,
    this.airlineIata,
    this.airlineIcao,
    this.flightNumber,
    this.flightIata,
    this.flightIcao,
  });

  factory Codeshared.fromJson(Map<String, dynamic> json) =>
      _$CodesharedFromJson(json);
  Map<String, dynamic> toJson() => _$CodesharedToJson(this);
}

@JsonSerializable()
class Aircraft {
  final String? registration;
  final String? iata;
  final String? icao;

  @JsonKey(name: 'icao24')
  final String? icao24;

  Aircraft({this.registration, this.iata, this.icao, this.icao24});

  factory Aircraft.fromJson(Map<String, dynamic> json) =>
      _$AircraftFromJson(json);
  Map<String, dynamic> toJson() => _$AircraftToJson(this);
}

@JsonSerializable()
class Live {
  final String? updated;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? direction;

  @JsonKey(name: 'speed_horizontal')
  final double? speedHorizontal;

  @JsonKey(name: 'speed_vertical')
  final double? speedVertical;

  @JsonKey(name: 'is_ground')
  final bool? isGround;

  Live({
    this.updated,
    this.latitude,
    this.longitude,
    this.altitude,
    this.direction,
    this.speedHorizontal,
    this.speedVertical,
    this.isGround,
  });

  factory Live.fromJson(Map<String, dynamic> json) => _$LiveFromJson(json);
  Map<String, dynamic> toJson() => _$LiveToJson(this);
}
