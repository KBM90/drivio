import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryService {
  static Future<void> createDeliveryRequest({
    required String category,
    required String description,
    required double latitude,
    required double longitude,
    String? pickupNotes,
    String? dropoffNotes,
  }) async {
    try {
      final passengerId = await AuthService.getPassengerId();
      if (passengerId == null) {
        throw Exception('Passenger profile not found');
      }

      await Supabase.instance.client.from('delivery_requests').insert({
        'passenger_id': passengerId,
        'category': category,
        'description': description,
        'pickup_notes': pickupNotes,
        'dropoff_notes': dropoffNotes,
        'status': 'pending',
        // Set delivery_location to provided location
        'delivery_location': 'SRID=4326;POINT($longitude $latitude)',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error creating delivery request: $e');
      throw Exception('Failed to create delivery request: $e');
    }
  }
}
