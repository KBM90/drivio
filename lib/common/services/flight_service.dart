import 'dart:convert';
import 'package:drivio_app/common/models/flight.dart';
import 'package:drivio_app/common/models/flight_filter.dart';
import 'package:drivio_app/common/services/airport_database.dart';
import 'package:drivio_app/common/services/mock_flight_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing flight data
///
/// Currently uses MockFlightDatabase for realistic test data.
/// To integrate with a real API:
/// 1. Sign up for a flight API (e.g., Air France-KLM, Aviationstack)
/// 2. Add API credentials to .env file
/// 3. Replace MockFlightDatabase calls with API requests
/// 4. Parse API responses into Flight objects
class FlightService {
  // Cache configuration
  static const String _cachePrefix = 'flight_cache_';
  static const Duration _cacheDuration = Duration(minutes: 15);

  /// Search for flights based on filter criteria
  /// Returns a list of flights matching the search parameters
  static Future<List<Flight>> searchFlights(FlightFilter filter) async {
    try {
      if (!filter.isValid) {
        throw Exception('Invalid filter: departure airport is required');
      }

      // Check cache first
      final cachedFlights = await _getCachedFlights(filter);
      if (cachedFlights != null) {
        debugPrint('✅ Returning cached flights');
        return cachedFlights;
      }

      debugPrint('🛫 Searching flights with mock data');
      debugPrint('   Departure: ${filter.departureIata}');
      debugPrint('   Arrival: ${filter.arrivalIata ?? "Any"}');
      debugPrint('   Start Date: ${filter.startDate}');
      debugPrint('   End Date: ${filter.endDate}');
      debugPrint('   Status: ${filter.flightStatus ?? "All"}');

      // Simulate network delay for realism
      await Future.delayed(const Duration(milliseconds: 800));

      // Use mock database - search for each day in the range
      final flights = MockFlightDatabase.searchFlights(
        departureIata: filter.departureIata!,
        arrivalIata: filter.arrivalIata,
        flightDate: filter.startDate ?? DateTime.now(),
        flightStatus: filter.flightStatus,
      );

      // Cache the results
      await _cacheFlights(filter, flights);

      debugPrint('✅ Found ${flights.length} flights (mock data)');
      return flights;
    } catch (e) {
      debugPrint('❌ Error searching flights: $e');
      rethrow;
    }
  }

  /// Search airports by name or IATA code for autocomplete
  /// Uses local database
  static Future<List<Airport>> searchAirports(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }

      // Check cache first
      final cachedAirports = await _getCachedAirports(query);
      if (cachedAirports != null) {
        debugPrint('✅ Returning cached airports for: $query');
        return cachedAirports;
      }

      // Use local airport database
      debugPrint('🔍 Searching local airport database for: $query');

      final airports = AirportDatabase.search(query);

      // Cache the results
      await _cacheAirports(query, airports);

      debugPrint('✅ Found ${airports.length} airports locally');
      return airports;
    } catch (e) {
      debugPrint('❌ Error searching airports: $e');
      rethrow;
    }
  }

  // Cache management methods
  static Future<List<Flight>?> _getCachedFlights(FlightFilter filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(filter);
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = DateTime.parse(data['timestamp'] as String);

        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          final flightsData = data['flights'] as List;
          return flightsData
              .map((json) => Flight.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // Cache expired, remove it
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      debugPrint('❌ Error reading cache: $e');
    }
    return null;
  }

  static Future<void> _cacheFlights(
    FlightFilter filter,
    List<Flight> flights,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(filter);
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'flights': flights.map((f) => f.toJson()).toList(),
      };
      await prefs.setString(cacheKey, json.encode(data));
    } catch (e) {
      debugPrint('❌ Error caching flights: $e');
    }
  }

  static Future<List<Airport>?> _getCachedAirports(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}airports_$query';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final data = json.decode(cachedData);
        final timestamp = DateTime.parse(data['timestamp'] as String);

        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          final airportsData = data['airports'] as List;
          return airportsData
              .map((json) => Airport.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // Cache expired, remove it
          await prefs.remove(cacheKey);
        }
      }
    } catch (e) {
      debugPrint('❌ Error reading airport cache: $e');
    }
    return null;
  }

  static Future<void> _cacheAirports(
    String query,
    List<Airport> airports,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cachePrefix}airports_$query';
      final data = {
        'timestamp': DateTime.now().toIso8601String(),
        'airports':
            airports
                .map(
                  (a) => {
                    'airport_name': a.name,
                    'iata_code': a.iata,
                    'icao_code': a.icao,
                    'city_name': a.city,
                    'country_name': a.country,
                  },
                )
                .toList(),
      };
      await prefs.setString(cacheKey, json.encode(data));
    } catch (e) {
      debugPrint('❌ Error caching airports: $e');
    }
  }

  static String _getCacheKey(FlightFilter filter) {
    final params = filter.toQueryParams();
    final sortedKeys = params.keys.toList()..sort();
    final keyString = sortedKeys.map((k) => '$k=${params[k]}').join('_');
    return '$_cachePrefix$keyString';
  }

  /// Clear all flight caches
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
      debugPrint('✅ Flight cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cache: $e');
    }
  }
}
