import 'dart:math';

import 'package:drivio_app/common/models/car_brand.dart';
import 'package:drivio_app/common/models/car_rental_request.dart';
import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarRentalService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all car brands for dropdown selection
  Future<List<CarBrand>> getCarBrands() async {
    try {
      final response = await _supabase
          .from('car_brands')
          .select()
          .order('company')
          .order('model');

      final brands =
          (response as List).map((json) => CarBrand.fromJson(json)).toList();

      debugPrint('✅ Loaded ${brands.length} car brands');
      return brands;
    } catch (e) {
      debugPrint('❌ Error loading car brands: $e');
      return [];
    }
  }

  /// Fetch available rental cars with optional filters
  Future<List<ProvidedCarRental>> getAvailableCars({
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    double? maxPrice,
    Location? userLocation,
  }) async {
    try {
      var query = _supabase
          .from('provided_car_rentals')
          .select('''
            *,
            car_brand:car_brands(
              id,
              company,
              model,
              thumbnail_image,
              category,
              average_consumption
            ),
            car_renter:car_renters!inner(
              id,
              user_id,
              business_name,
              city,
              rating,
              is_verified,
              user:users!inner(
                id,
                name,
                phone,
                profile_image_path
              )
            )
          ''')
          .eq('is_available', true);

      // Apply city filter
      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }

      // Apply price filter
      if (maxPrice != null) {
        query = query.lte('daily_price', maxPrice);
      }

      final response = await query;

      List<ProvidedCarRental> cars =
          (response as List)
              .map((json) => ProvidedCarRental.fromJson(json))
              .toList();

      // Calculate distances if user location is provided
      if (userLocation != null &&
          userLocation.latitude != null &&
          userLocation.longitude != null) {
        cars =
            cars.map((car) {
              if (car.location?.latitude != null &&
                  car.location?.longitude != null) {
                final distance = _calculateDistance(
                  userLocation.latitude!,
                  userLocation.longitude!,
                  car.location!.latitude!,
                  car.location!.longitude!,
                );
                return car.copyWith(distance: distance);
              }
              return car;
            }).toList();

        // Sort by distance
        cars.sort((a, b) {
          if (a.distance == null) return 1;
          if (b.distance == null) return -1;
          return a.distance!.compareTo(b.distance!);
        });
      }

      debugPrint('✅ Loaded ${cars.length} available rental cars');
      return cars;
    } catch (e) {
      debugPrint('❌ Error loading rental cars: $e');
      return [];
    }
  }

  /// Get unique cities where cars are available
  Future<List<String>> getAvailableCities() async {
    try {
      final response = await _supabase
          .from('provided_car_rentals')
          .select('city')
          .eq('is_available', true);

      final cities =
          (response as List)
              .map((item) => item['city'] as String)
              .toSet()
              .toList();

      cities.sort();
      return cities;
    } catch (e) {
      debugPrint('❌ Error loading cities: $e');
      return [];
    }
  }

  /// Get all cars for a specific renter
  Future<List<ProvidedCarRental>> getCarsByRenterId(int renterId) async {
    try {
      final response = await _supabase
          .from('provided_car_rentals')
          .select('''
            *,
            car_brand:car_brands(
              id,
              company,
              model,
              thumbnail_image,
              category,
              average_consumption
            ),
            car_renter:car_renters!inner(
              id,
              user_id,
              business_name,
              city,
              rating,
              is_verified
            )
          ''')
          .eq('car_renter_id', renterId)
          .order('created_at', ascending: false);

      final cars =
          (response as List)
              .map((json) => ProvidedCarRental.fromJson(json))
              .toList();

      debugPrint('✅ Loaded ${cars.length} cars for renter $renterId');
      return cars;
    } catch (e) {
      debugPrint('❌ Error loading renter cars: $e');
      return [];
    }
  }

  /// Create a new rental request
  Future<CarRentalRequest?> createRentalRequest({
    required int carRentalId,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
  }) async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) {
        debugPrint('❌ User not authenticated');
        return null;
      }

      // Get car details to calculate price
      final carResponse =
          await _supabase
              .from('provided_car_rentals')
              .select('daily_price')
              .eq('id', carRentalId)
              .single();

      final dailyPrice = (carResponse['daily_price'] as num).toDouble();
      final totalDays = endDate.difference(startDate).inDays + 1;
      final totalPrice = dailyPrice * totalDays;

      final response =
          await _supabase
              .from('car_rental_requests')
              .insert({
                'user_id': userId,
                'car_rental_id': carRentalId,
                'start_date': startDate.toIso8601String().split('T')[0],
                'end_date': endDate.toIso8601String().split('T')[0],
                'total_price': totalPrice,
                'notes': notes,
              })
              .select()
              .single();

      debugPrint('✅ Rental request created successfully');
      return CarRentalRequest.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating rental request: $e');
      return null;
    }
  }

  /// Get user's rental requests
  Future<List<CarRentalRequest>> getUserRentalRequests() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) return [];

      final response = await _supabase
          .from('car_rental_requests')
          .select('''
            *,
            car_rental:provided_car_rentals!inner(
              id,
              model,
              year,
              daily_price,
              images
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final requests =
          (response as List)
              .map((json) => CarRentalRequest.fromJson(json))
              .toList();

      debugPrint('✅ Loaded ${requests.length} rental requests');
      return requests;
    } catch (e) {
      debugPrint('❌ Error loading rental requests: $e');
      return [];
    }
  }

  /// Get rental requests for a specific car renter
  Future<List<CarRentalRequest>> getRentalRequestsForRenter(
    int renterId,
  ) async {
    try {
      final response = await _supabase
          .from('car_rental_requests')
          .select('''
            *,
            car_rental:provided_car_rentals!inner(
              id,
              model,
              year,
              daily_price,
              images,
              car_renter_id
            )
          ''')
          .eq('car_rental.car_renter_id', renterId)
          .order('created_at', ascending: false);

      final requests =
          (response as List)
              .map((json) => CarRentalRequest.fromJson(json))
              .toList();

      debugPrint('✅ Loaded ${requests.length} requests for renter $renterId');
      return requests;
    } catch (e) {
      debugPrint('❌ Error loading renter requests: $e');
      return [];
    }
  }

  /// Add a new car rental
  Future<ProvidedCarRental?> addCarRental({
    required int carRenterId,
    required int carBrandId,
    required int year,
    required String color,
    required String city,
    required double dailyPrice,
    String? plateNumber,
    Map<String, dynamic>? features,
  }) async {
    try {
      final response =
          await _supabase
              .from('provided_car_rentals')
              .insert({
                'car_renter_id': carRenterId,
                'car_brand_id': carBrandId,
                'year': year,
                'color': color,
                'city': city,
                'daily_price': dailyPrice,
                'plate_number': plateNumber,
                'features': features,
                'is_available': true,
              })
              .select()
              .single();

      debugPrint('✅ Added new car rental');
      return ProvidedCarRental.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error adding car rental: $e');
      return null;
    }
  }

  /// Update an existing car rental
  Future<bool> updateCarRental({
    required int carId,
    int? carBrandId,
    int? year,
    String? color,
    String? city,
    double? dailyPrice,
    String? plateNumber,
    bool? isAvailable,
    DateTime? unavailableFrom,
    DateTime? unavailableUntil,
    Map<String, dynamic>? features,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (carBrandId != null) updates['car_brand_id'] = carBrandId;
      if (year != null) updates['year'] = year;
      if (color != null) updates['color'] = color;
      if (city != null) updates['city'] = city;
      if (dailyPrice != null) updates['daily_price'] = dailyPrice;
      if (plateNumber != null) updates['plate_number'] = plateNumber;
      if (isAvailable != null) updates['is_available'] = isAvailable;
      if (unavailableFrom != null)
        updates['unavailable_from'] = unavailableFrom.toIso8601String();
      if (unavailableUntil != null)
        updates['unavailable_until'] = unavailableUntil.toIso8601String();
      if (features != null) updates['features'] = features;

      await _supabase
          .from('provided_car_rentals')
          .update(updates)
          .eq('id', carId);

      debugPrint('✅ Updated car rental $carId');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating car rental: $e');
      return false;
    }
  }

  /// Delete a car rental
  Future<bool> deleteCarRental(int carId) async {
    try {
      await _supabase.from('provided_car_rentals').delete().eq('id', carId);

      debugPrint('✅ Deleted car rental $carId');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting car rental: $e');
      return false;
    }
  }

  /// Update rental request status
  Future<bool> updateRequestStatus({
    required int requestId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('car_rental_requests')
          .update({'status': status})
          .eq('id', requestId);

      debugPrint('✅ Updated request $requestId to $status');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating request status: $e');
      return false;
    }
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
