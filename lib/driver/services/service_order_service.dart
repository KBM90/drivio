import 'package:drivio_app/common/models/service_order.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceOrderService {
  final _supabase = Supabase.instance.client;

  /// Create a new service order (regular or custom)
  /// For regular orders: provide serviceId and providerId
  /// For custom orders: provide customServiceName and category
  Future<ServiceOrder?> createOrder({
    int? serviceId,
    int? providerId,
    String? customServiceName,
    String? category,
    required String driverName,
    required String driverPhone,
    String? driverLocation, // PostGIS format: "POINT(lng lat)"
    int quantity = 1,
    String? notes,
    String preferredContactMethod = 'phone',
  }) async {
    try {
      // Validation: Either serviceId OR (customServiceName AND category) must be provided
      if (serviceId == null &&
          (customServiceName == null || category == null)) {
        throw Exception(
          'Either serviceId OR both customServiceName and category must be provided',
        );
      }
      if (serviceId != null &&
          (customServiceName != null || category != null)) {
        throw Exception(
          'Cannot provide both serviceId and custom order fields',
        );
      }

      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      // Ensure session is valid
      await AuthService.ensureValidSession();

      final orderData = {
        'driver_id': driverId,
        'quantity': quantity,
        'notes': notes,
        'preferred_contact_method': preferredContactMethod,
        'driver_name': driverName,
        'driver_phone': driverPhone,
        'driver_location': driverLocation,
        'status': 'pending',
      };

      // Add fields based on order type
      if (serviceId != null) {
        // Regular order
        orderData['service_id'] = serviceId;
        orderData['provider_id'] = providerId;
      } else {
        // Custom order
        orderData['custom_service_name'] = customServiceName;
        orderData['category'] = category;
      }

      final response =
          await _supabase
              .from('service_orders')
              .insert(orderData)
              .select()
              .single();

      return ServiceOrder.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating order: $e');
      rethrow;
    }
  }

  /// Get all orders for the current driver
  Future<List<ServiceOrder>> getDriverOrders({String? status}) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      await AuthService.ensureValidSession();

      dynamic query = _supabase
          .from('service_orders')
          .select('*, provided_services(name, price, currency)')
          .eq('driver_id', driverId);

      if (status != null) {
        query = query.eq('status', status);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;

      return (response as List)
          .map((json) => ServiceOrder.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching driver orders: $e');
      rethrow;
    }
  }

  /// Get a specific order by ID
  Future<ServiceOrder?> getOrderById(int orderId) async {
    try {
      await AuthService.ensureValidSession();

      final response =
          await _supabase
              .from('service_orders')
              .select(
                '*, provided_services(name, price, currency, description)',
              )
              .eq('id', orderId)
              .single();

      return ServiceOrder.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching order $orderId: $e');
      rethrow;
    }
  }

  /// Cancel an order (only if status is 'pending')
  Future<bool> cancelOrder(int orderId) async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      await AuthService.ensureValidSession();

      // Only allow cancelling pending orders
      await _supabase
          .from('service_orders')
          .update({'status': 'cancelled'})
          .eq('id', orderId)
          .eq('driver_id', driverId)
          .eq('status', 'pending');

      return true;
    } catch (e) {
      debugPrint('❌ Error cancelling order $orderId: $e');
      return false;
    }
  }

  /// Get order count by status for the current driver
  Future<Map<String, int>> getOrderCountsByStatus() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        throw Exception('Driver not found');
      }

      await AuthService.ensureValidSession();

      final response = await _supabase
          .from('service_orders')
          .select('status')
          .eq('driver_id', driverId);

      final counts = <String, int>{
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      };

      for (var order in response) {
        final status = order['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('❌ Error fetching order counts: $e');
      return {};
    }
  }
}
