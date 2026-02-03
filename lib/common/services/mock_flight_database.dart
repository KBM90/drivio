import 'package:drivio_app/common/models/flight.dart';

/// Mock flight database for testing and demonstration
/// This provides realistic flight data without requiring API calls
///
/// To switch to real API (Air France-KLM):
/// 1. Sign up at https://developer.airfranceklm.com/
/// 2. Get your free API key
/// 3. Update FlightService to call the real API
class MockFlightDatabase {
  /// Generate mock flights based on search criteria
  static List<Flight> searchFlights({
    required String departureIata,
    String? arrivalIata,
    required DateTime flightDate,
    String? flightStatus,
  }) {
    // Filter flights by criteria
    final allFlights = _getAllFlights(flightDate);

    return allFlights.where((flight) {
      // Filter by departure airport
      if (flight.departure?.iata?.toUpperCase() !=
          departureIata.toUpperCase()) {
        return false;
      }

      // Filter by arrival airport if specified
      if (arrivalIata != null && arrivalIata.isNotEmpty) {
        if (flight.arrival?.iata?.toUpperCase() != arrivalIata.toUpperCase()) {
          return false;
        }
      }

      // Filter by status if specified
      if (flightStatus != null && flightStatus != 'all') {
        if (flight.flightStatus?.toLowerCase() != flightStatus.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Generate realistic flight data for a given date
  static List<Flight> _getAllFlights(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return [
      // Casablanca (CMN) departures
      _createFlight(
        date: dateStr,
        flightNumber: 'AT200',
        airline: 'Royal Air Maroc',
        airlineIata: 'AT',
        depAirport: 'Mohammed V International',
        depIata: 'CMN',
        depTime: '08:00',
        arrAirport: 'Paris Charles de Gaulle',
        arrIata: 'CDG',
        arrTime: '12:30',
        status: 'scheduled',
      ),
      _createFlight(
        date: dateStr,
        flightNumber: 'AF1397',
        airline: 'Air France',
        airlineIata: 'AF',
        depAirport: 'Mohammed V International',
        depIata: 'CMN',
        depTime: '10:15',
        arrAirport: 'Paris Charles de Gaulle',
        arrIata: 'CDG',
        arrTime: '14:45',
        status: 'active',
        delay: 15,
      ),
      _createFlight(
        date: dateStr,
        flightNumber: 'AT202',
        airline: 'Royal Air Maroc',
        airlineIata: 'AT',
        depAirport: 'Mohammed V International',
        depIata: 'CMN',
        depTime: '14:30',
        arrAirport: 'Madrid-Barajas',
        arrIata: 'MAD',
        arrTime: '17:00',
        status: 'scheduled',
      ),
      _createFlight(
        date: dateStr,
        flightNumber: 'AT204',
        airline: 'Royal Air Maroc',
        airlineIata: 'AT',
        depAirport: 'Mohammed V International',
        depIata: 'CMN',
        depTime: '16:45',
        arrAirport: 'London Heathrow',
        arrIata: 'LHR',
        arrTime: '20:15',
        status: 'scheduled',
      ),
      _createFlight(
        date: dateStr,
        flightNumber: 'KL1705',
        airline: 'KLM',
        airlineIata: 'KL',
        depAirport: 'Mohammed V International',
        depIata: 'CMN',
        depTime: '18:00',
        arrAirport: 'Amsterdam Schiphol',
        arrIata: 'AMS',
        arrTime: '22:30',
        status: 'scheduled',
      ),

      // Paris (CDG) departures
      _createFlight(
        date: dateStr,
        flightNumber: 'AF1396',
        airline: 'Air France',
        airlineIata: 'AF',
        depAirport: 'Paris Charles de Gaulle',
        depIata: 'CDG',
        depTime: '07:00',
        arrAirport: 'Mohammed V International',
        arrIata: 'CMN',
        arrTime: '09:30',
        status: 'landed',
      ),
      _createFlight(
        date: dateStr,
        flightNumber: 'AF1398',
        airline: 'Air France',
        airlineIata: 'AF',
        depAirport: 'Paris Charles de Gaulle',
        depIata: 'CDG',
        depTime: '15:30',
        arrAirport: 'Mohammed V International',
        arrIata: 'CMN',
        arrTime: '18:00',
        status: 'scheduled',
      ),
      _createFlight(
        date: dateStr,
        flightNumber: 'AF447',
        airline: 'Air France',
        airlineIata: 'AF',
        depAirport: 'Paris Charles de Gaulle',
        depIata: 'CDG',
        depTime: '11:00',
        arrAirport: 'John F. Kennedy International',
        arrIata: 'JFK',
        arrTime: '13:30',
        status: 'active',
      ),

      // New York (JFK) departures
      _createFlight(
        date: dateStr,
        flightNumber: 'AF008',
        airline: 'Air France',
        airlineIata: 'AF',
        depAirport: 'John F. Kennedy International',
        depIata: 'JFK',
        depTime: '18:00',
        arrAirport: 'Paris Charles de Gaulle',
        arrIata: 'CDG',
        arrTime: '07:30',
        status: 'scheduled',
      ),
      _createFlight(
        date: dateStr,
        flightNumber: 'AA100',
        airline: 'American Airlines',
        airlineIata: 'AA',
        depAirport: 'John F. Kennedy International',
        depIata: 'JFK',
        depTime: '08:00',
        arrAirport: 'Los Angeles International',
        arrIata: 'LAX',
        arrTime: '11:30',
        status: 'landed',
      ),

      // Add more routes as needed
      _createFlight(
        date: dateStr,
        flightNumber: 'AT206',
        airline: 'Royal Air Maroc',
        airlineIata: 'AT',
        depAirport: 'Mohammed V International',
        depIata: 'CMN',
        depTime: '20:00',
        arrAirport: 'Dubai International',
        arrIata: 'DXB',
        arrTime: '05:30',
        status: 'scheduled',
      ),
      _createFlight(
        date: dateStr,
        flightNumber: 'AT100',
        airline: 'Royal Air Maroc',
        airlineIata: 'AT',
        depAirport: 'Mohammed V International',
        depIata: 'CMN',
        depTime: '22:30',
        arrAirport: 'Cairo International',
        arrIata: 'CAI',
        arrTime: '04:00',
        status: 'cancelled',
      ),
    ];
  }

  static Flight _createFlight({
    required String date,
    required String flightNumber,
    required String airline,
    required String airlineIata,
    required String depAirport,
    required String depIata,
    required String depTime,
    required String arrAirport,
    required String arrIata,
    required String arrTime,
    required String status,
    int? delay,
  }) {
    final depDateTime = DateTime.parse('$date $depTime:00');
    final arrDateTime = DateTime.parse('$date $arrTime:00');

    return Flight(
      flightDate: date,
      flightStatus: status,
      departure: Departure(
        airport: depAirport,
        iata: depIata,
        terminal: _getRandomTerminal(),
        gate: _getRandomGate(),
        delay: delay,
        scheduled: depDateTime.toIso8601String(),
        estimated:
            delay != null
                ? depDateTime.add(Duration(minutes: delay)).toIso8601String()
                : depDateTime.toIso8601String(),
      ),
      arrival: Arrival(
        airport: arrAirport,
        iata: arrIata,
        terminal: _getRandomTerminal(),
        gate: _getRandomGate(),
        delay: delay,
        scheduled: arrDateTime.toIso8601String(),
        estimated:
            delay != null
                ? arrDateTime.add(Duration(minutes: delay)).toIso8601String()
                : arrDateTime.toIso8601String(),
      ),
      airline: Airline(name: airline, iata: airlineIata),
      flight: FlightInfo(number: flightNumber, iata: flightNumber),
    );
  }

  static String _getRandomTerminal() {
    final terminals = ['1', '2', '2A', '2B', '2C', '2D', '2E', '2F', '3'];
    return terminals[DateTime.now().millisecond % terminals.length];
  }

  static String _getRandomGate() {
    final gates = ['A1', 'A2', 'B3', 'C4', 'D5', 'E6', 'F7', 'G8'];
    return gates[DateTime.now().millisecond % gates.length];
  }
}
