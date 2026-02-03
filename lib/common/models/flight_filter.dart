class FlightFilter {
  final String? departureIata;
  final String? arrivalIata;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? airlineIata;
  final String? flightStatus;
  final FlightSortOption sortBy;

  FlightFilter({
    this.departureIata,
    this.arrivalIata,
    this.startDate,
    this.endDate,
    this.airlineIata,
    this.flightStatus,
    this.sortBy = FlightSortOption.time,
  });

  FlightFilter copyWith({
    String? departureIata,
    String? arrivalIata,
    DateTime? startDate,
    DateTime? endDate,
    String? airlineIata,
    String? flightStatus,
    FlightSortOption? sortBy,
  }) {
    return FlightFilter(
      departureIata: departureIata ?? this.departureIata,
      arrivalIata: arrivalIata ?? this.arrivalIata,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      airlineIata: airlineIata ?? this.airlineIata,
      flightStatus: flightStatus ?? this.flightStatus,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get isValid {
    // At minimum, we need a departure airport
    return departureIata != null && departureIata!.isNotEmpty;
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};

    if (departureIata != null && departureIata!.isNotEmpty) {
      params['dep_iata'] = departureIata!;
    }

    if (arrivalIata != null && arrivalIata!.isNotEmpty) {
      params['arr_iata'] = arrivalIata!;
    }

    if (startDate != null) {
      params['start_date'] =
          '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}-${startDate!.day.toString().padLeft(2, '0')}';
    }

    if (endDate != null) {
      params['end_date'] =
          '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';
    }

    if (airlineIata != null && airlineIata!.isNotEmpty) {
      params['airline_iata'] = airlineIata!;
    }

    if (flightStatus != null &&
        flightStatus!.isNotEmpty &&
        flightStatus != 'all') {
      params['flight_status'] = flightStatus!;
    }

    return params;
  }
}

enum FlightSortOption { time, airline, status }

class Airport {
  final String name;
  final String iata;
  final String? icao;
  final String? city;
  final String? country;

  Airport({
    required this.name,
    required this.iata,
    this.icao,
    this.city,
    this.country,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      name: json['airport_name'] as String,
      iata: json['iata_code'] as String,
      icao: json['icao_code'] as String?,
      city: json['city_name'] as String?,
      country: json['country_name'] as String?,
    );
  }

  String get displayName {
    if (city != null) {
      return '$name ($iata) - $city';
    }
    return '$name ($iata)';
  }
}
