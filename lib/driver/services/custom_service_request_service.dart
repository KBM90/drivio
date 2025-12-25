import 'package:drivio_app/common/models/custom_service_request.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomServiceRequestService {
  final _supabase = Supabase.instance.client;

  /// Create a new custom service request
  Future<CustomServiceRequest?> createRequest({
    required String serviceName,
    required String category,
    required String description,
    required String driverName,
    required String driverPhone,
    String? driverLocation, // PostGIS format: "POINT(lng lat)"
    int quantity = 1,
    String? notes,
    String preferredContactMethod = 'phone',
  }) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      // Ensure session is valid
      await AuthService.ensureValidSession();

      final requestData = {
        'driver_id': driverId,
        'service_name': serviceName,
        'category': category,
        'description': description,
        'quantity': quantity,
        'notes': notes,
        'preferred_contact_method': preferredContactMethod,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'driver_location': driverLocation,
        'status': 'pending',
      };

      final response =
          await _supabase
              .from('custom_service_requests')
              .insert(requestData)
              .select()
              .single();

      return CustomServiceRequest.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating custom request: $e');
      rethrow;
    }
  }

  /// Get all custom requests for the current driver
  Future<List<CustomServiceRequest>> getDriverRequests({String? status}) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      await AuthService.ensureValidSession();

      dynamic query = _supabase
          .from('custom_service_requests')
          .select()
          .eq('driver_id', driverId);

      if (status != null) {
        query = query.eq('status', status);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;

      return (response as List)
          .map((json) => CustomServiceRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching driver custom requests: $e');
      rethrow;
    }
  }

  /// Get a specific custom request by ID
  Future<CustomServiceRequest?> getRequestById(int requestId) async {
    try {
      await AuthService.ensureValidSession();

      final response =
          await _supabase
              .from('custom_service_requests')
              .select()
              .eq('id', requestId)
              .single();

      return CustomServiceRequest.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching custom request $requestId: $e');
      rethrow;
    }
  }

  /// Cancel a custom request (only if status is 'pending')
  Future<bool> cancelRequest(int requestId) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      await AuthService.ensureValidSession();

      // Only allow cancelling pending requests
      await _supabase
          .from('custom_service_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId)
          .eq('driver_id', driverId)
          .eq('status', 'pending');

      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling custom request $requestId: $e');
      return false;
    }
  }

  /// Get request count by status for the current driver
  Future<Map<String, int>> getRequestCountsByStatus() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      await AuthService.ensureValidSession();

      final response = await _supabase
          .from('custom_service_requests')
          .select('status')
          .eq('driver_id', driverId);

      final counts = <String, int>{
        'pending': 0,
        'contacted': 0,
        'fulfilled': 0,
        'cancelled': 0,
      };

      for (var request in response) {
        final status = request['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('❌ Error fetching custom request counts: $e');
      return {};
    }
  }
}
