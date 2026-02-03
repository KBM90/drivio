import 'package:drivio_app/common/models/flight_filter.dart';

/// Local database of major airports worldwide
/// This is used because Aviationstack free tier doesn't support airport search
class AirportDatabase {
  static final List<Airport> _airports = [
    // North America - USA
    Airport(
      name: 'John F. Kennedy International Airport',
      iata: 'JFK',
      icao: 'KJFK',
      city: 'New York',
      country: 'United States',
    ),
    Airport(
      name: 'Los Angeles International Airport',
      iata: 'LAX',
      icao: 'KLAX',
      city: 'Los Angeles',
      country: 'United States',
    ),
    Airport(
      name: 'Chicago O\'Hare International Airport',
      iata: 'ORD',
      icao: 'KORD',
      city: 'Chicago',
      country: 'United States',
    ),
    Airport(
      name: 'Dallas/Fort Worth International Airport',
      iata: 'DFW',
      icao: 'KDFW',
      city: 'Dallas',
      country: 'United States',
    ),
    Airport(
      name: 'Denver International Airport',
      iata: 'DEN',
      icao: 'KDEN',
      city: 'Denver',
      country: 'United States',
    ),
    Airport(
      name: 'San Francisco International Airport',
      iata: 'SFO',
      icao: 'KSFO',
      city: 'San Francisco',
      country: 'United States',
    ),
    Airport(
      name: 'Seattle-Tacoma International Airport',
      iata: 'SEA',
      icao: 'KSEA',
      city: 'Seattle',
      country: 'United States',
    ),
    Airport(
      name: 'Miami International Airport',
      iata: 'MIA',
      icao: 'KMIA',
      city: 'Miami',
      country: 'United States',
    ),
    Airport(
      name: 'Boston Logan International Airport',
      iata: 'BOS',
      icao: 'KBOS',
      city: 'Boston',
      country: 'United States',
    ),
    Airport(
      name: 'Atlanta Hartsfield-Jackson International Airport',
      iata: 'ATL',
      icao: 'KATL',
      city: 'Atlanta',
      country: 'United States',
    ),

    // Europe
    Airport(
      name: 'London Heathrow Airport',
      iata: 'LHR',
      icao: 'EGLL',
      city: 'London',
      country: 'United Kingdom',
    ),
    Airport(
      name: 'Paris Charles de Gaulle Airport',
      iata: 'CDG',
      icao: 'LFPG',
      city: 'Paris',
      country: 'France',
    ),
    Airport(
      name: 'Amsterdam Airport Schiphol',
      iata: 'AMS',
      icao: 'EHAM',
      city: 'Amsterdam',
      country: 'Netherlands',
    ),
    Airport(
      name: 'Frankfurt Airport',
      iata: 'FRA',
      icao: 'EDDF',
      city: 'Frankfurt',
      country: 'Germany',
    ),
    Airport(
      name: 'Madrid-Barajas Airport',
      iata: 'MAD',
      icao: 'LEMD',
      city: 'Madrid',
      country: 'Spain',
    ),
    Airport(
      name: 'Barcelona-El Prat Airport',
      iata: 'BCN',
      icao: 'LEBL',
      city: 'Barcelona',
      country: 'Spain',
    ),
    Airport(
      name: 'Rome Fiumicino Airport',
      iata: 'FCO',
      icao: 'LIRF',
      city: 'Rome',
      country: 'Italy',
    ),
    Airport(
      name: 'Munich Airport',
      iata: 'MUC',
      icao: 'EDDM',
      city: 'Munich',
      country: 'Germany',
    ),
    Airport(
      name: 'Zurich Airport',
      iata: 'ZRH',
      icao: 'LSZH',
      city: 'Zurich',
      country: 'Switzerland',
    ),
    Airport(
      name: 'Vienna International Airport',
      iata: 'VIE',
      icao: 'LOWW',
      city: 'Vienna',
      country: 'Austria',
    ),

    // Middle East & Africa
    Airport(
      name: 'Dubai International Airport',
      iata: 'DXB',
      icao: 'OMDB',
      city: 'Dubai',
      country: 'United Arab Emirates',
    ),
    Airport(
      name: 'Abu Dhabi International Airport',
      iata: 'AUH',
      icao: 'OMAA',
      city: 'Abu Dhabi',
      country: 'United Arab Emirates',
    ),
    Airport(
      name: 'Doha Hamad International Airport',
      iata: 'DOH',
      icao: 'OTHH',
      city: 'Doha',
      country: 'Qatar',
    ),
    Airport(
      name: 'Istanbul Airport',
      iata: 'IST',
      icao: 'LTFM',
      city: 'Istanbul',
      country: 'Turkey',
    ),
    Airport(
      name: 'Cairo International Airport',
      iata: 'CAI',
      icao: 'HECA',
      city: 'Cairo',
      country: 'Egypt',
    ),
    Airport(
      name: 'Casablanca Mohammed V International Airport',
      iata: 'CMN',
      icao: 'GMMN',
      city: 'Casablanca',
      country: 'Morocco',
    ),

    // Morocco - Additional airports
    Airport(
      name: 'Rabat-Salé Airport',
      iata: 'RBA',
      icao: 'GMME',
      city: 'Rabat',
      country: 'Morocco',
    ),
    Airport(
      name: 'Marrakech Menara Airport',
      iata: 'RAK',
      icao: 'GMMX',
      city: 'Marrakech',
      country: 'Morocco',
    ),
    Airport(
      name: 'Agadir-Al Massira Airport',
      iata: 'AGA',
      icao: 'GMAD',
      city: 'Agadir',
      country: 'Morocco',
    ),
    Airport(
      name: 'Tangier Ibn Battouta Airport',
      iata: 'TNG',
      icao: 'GMTT',
      city: 'Tangier',
      country: 'Morocco',
    ),
    Airport(
      name: 'Fes-Saïss Airport',
      iata: 'FEZ',
      icao: 'GMFF',
      city: 'Fes',
      country: 'Morocco',
    ),
    Airport(
      name: 'Nador International Airport',
      iata: 'NDR',
      icao: 'GMMW',
      city: 'Nador',
      country: 'Morocco',
    ),
    Airport(
      name: 'Oujda Angads Airport',
      iata: 'OUD',
      icao: 'GMFO',
      city: 'Oujda',
      country: 'Morocco',
    ),

    // Asia
    Airport(
      name: 'Tokyo Haneda Airport',
      iata: 'HND',
      icao: 'RJTT',
      city: 'Tokyo',
      country: 'Japan',
    ),
    Airport(
      name: 'Tokyo Narita International Airport',
      iata: 'NRT',
      icao: 'RJAA',
      city: 'Tokyo',
      country: 'Japan',
    ),
    Airport(
      name: 'Beijing Capital International Airport',
      iata: 'PEK',
      icao: 'ZBAA',
      city: 'Beijing',
      country: 'China',
    ),
    Airport(
      name: 'Shanghai Pudong International Airport',
      iata: 'PVG',
      icao: 'ZSPD',
      city: 'Shanghai',
      country: 'China',
    ),
    Airport(
      name: 'Hong Kong International Airport',
      iata: 'HKG',
      icao: 'VHHH',
      city: 'Hong Kong',
      country: 'Hong Kong',
    ),
    Airport(
      name: 'Singapore Changi Airport',
      iata: 'SIN',
      icao: 'WSSS',
      city: 'Singapore',
      country: 'Singapore',
    ),
    Airport(
      name: 'Bangkok Suvarnabhumi Airport',
      iata: 'BKK',
      icao: 'VTBS',
      city: 'Bangkok',
      country: 'Thailand',
    ),
    Airport(
      name: 'Seoul Incheon International Airport',
      iata: 'ICN',
      icao: 'RKSI',
      city: 'Seoul',
      country: 'South Korea',
    ),
    Airport(
      name: 'Kuala Lumpur International Airport',
      iata: 'KUL',
      icao: 'WMKK',
      city: 'Kuala Lumpur',
      country: 'Malaysia',
    ),

    // Australia & Oceania
    Airport(
      name: 'Sydney Kingsford Smith Airport',
      iata: 'SYD',
      icao: 'YSSY',
      city: 'Sydney',
      country: 'Australia',
    ),
    Airport(
      name: 'Melbourne Airport',
      iata: 'MEL',
      icao: 'YMML',
      city: 'Melbourne',
      country: 'Australia',
    ),
    Airport(
      name: 'Brisbane Airport',
      iata: 'BNE',
      icao: 'YBBN',
      city: 'Brisbane',
      country: 'Australia',
    ),
    Airport(
      name: 'Auckland Airport',
      iata: 'AKL',
      icao: 'NZAA',
      city: 'Auckland',
      country: 'New Zealand',
    ),

    // South America
    Airport(
      name: 'São Paulo-Guarulhos International Airport',
      iata: 'GRU',
      icao: 'SBGR',
      city: 'São Paulo',
      country: 'Brazil',
    ),
    Airport(
      name: 'Rio de Janeiro-Galeão International Airport',
      iata: 'GIG',
      icao: 'SBGL',
      city: 'Rio de Janeiro',
      country: 'Brazil',
    ),
    Airport(
      name: 'Buenos Aires Ezeiza International Airport',
      iata: 'EZE',
      icao: 'SAEZ',
      city: 'Buenos Aires',
      country: 'Argentina',
    ),
    Airport(
      name: 'Bogotá El Dorado International Airport',
      iata: 'BOG',
      icao: 'SKBO',
      city: 'Bogotá',
      country: 'Colombia',
    ),
    Airport(
      name: 'Lima Jorge Chávez International Airport',
      iata: 'LIM',
      icao: 'SPJC',
      city: 'Lima',
      country: 'Peru',
    ),

    // Canada
    Airport(
      name: 'Toronto Pearson International Airport',
      iata: 'YYZ',
      icao: 'CYYZ',
      city: 'Toronto',
      country: 'Canada',
    ),
    Airport(
      name: 'Vancouver International Airport',
      iata: 'YVR',
      icao: 'CYVR',
      city: 'Vancouver',
      country: 'Canada',
    ),
    Airport(
      name: 'Montreal-Pierre Elliott Trudeau International Airport',
      iata: 'YUL',
      icao: 'CYUL',
      city: 'Montreal',
      country: 'Canada',
    ),
  ];

  /// Search airports by name, IATA code, or city
  static List<Airport> search(String query) {
    if (query.isEmpty) {
      return [];
    }

    final lowerQuery = query.toLowerCase();

    return _airports
        .where((airport) {
          return airport.name.toLowerCase().contains(lowerQuery) ||
              airport.iata.toLowerCase().contains(lowerQuery) ||
              (airport.city?.toLowerCase().contains(lowerQuery) ?? false) ||
              (airport.country?.toLowerCase().contains(lowerQuery) ?? false);
        })
        .take(10)
        .toList();
  }

  /// Get all airports
  static List<Airport> getAll() {
    return List.from(_airports);
  }

  /// Get airport by IATA code
  static Airport? getByIata(String iata) {
    try {
      return _airports.firstWhere(
        (airport) => airport.iata.toUpperCase() == iata.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
