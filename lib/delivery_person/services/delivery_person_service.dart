import 'package:drivio_app/common/helpers/custom_exceptions.dart';
import 'package:drivio_app/common/models/delivery_request.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/delivery_person/models/delivery_person.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryPersonService {
  /// Get delivery person data
  static Future<DeliveryPerson> getDeliveryPerson() async {
    try {
      final supabase = Supabase.instance.client;

      // Get authenticated user
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw UnauthorizedException(
          'User not authenticated. Please login again.',
        );
      }

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      // Get internal user ID
      final userResponse =
          await supabase
              .from('users')
              .select('id')
              .eq('user_id', userId)
              .single();

      final internalUserId = userResponse['id'] as int;

      // Get delivery person data with user information
      final deliveryPersonResponse =
          await supabase
              .from('delivery_persons')
              .select('''
          id,
          user_id,
          vehicle_type,
          vehicle_plate,
          is_available,
          current_location,
          rating,
          created_at,
          updated_at,
          user:users!inner(
            id,
            name,
            email,
            phone,
            country_code,
            country,
            language,
            sexe,
            is_verified,
            city,
            role,
            profile_image_path,
            banned,
            email_verified_at,
            created_at,
            updated_at,
            user_id
          )
        ''')
              .eq('user_id', internalUserId)
              .single();

      return DeliveryPerson.fromJson(deliveryPersonResponse);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw NotFoundException('Delivery person not found.');
      }
      throw ServerErrorException('Database error: ${e.message}');
    } on AuthException catch (e) {
      throw UnauthorizedException('Authentication error: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error fetching delivery person: $e');
      throw Exception('Failed to fetch delivery person: $e');
    }
  }

  /// Update delivery person location in Supabase
  static Future<void> updateDeliveryPersonLocation(
    double latitude,
    double longitude,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // Get authenticated user
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw UnauthorizedException('User not authenticated');
      }

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      // Get internal user ID
      final userResponse =
          await supabase
              .from('users')
              .select('id')
              .eq('user_id', userId)
              .single();

      final internalUserId = userResponse['id'] as int;

      // Get delivery person ID
      final deliveryPersonResponse =
          await supabase
              .from('delivery_persons')
              .select('id')
              .eq('user_id', internalUserId)
              .single();

      final deliveryPersonId = deliveryPersonResponse['id'] as int;

      debugPrint(
        '🔍 Updating location for delivery person ID: $deliveryPersonId',
      );
      debugPrint('🔍 User ID: $userId, Internal User ID: $internalUserId');
      debugPrint('🔍 Location: POINT($longitude $latitude)');

      // Update location using geometry type (same as drivers table)
      final result =
          await supabase
              .from('delivery_persons')
              .update({
                'current_location': 'POINT($longitude $latitude)',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', deliveryPersonId)
              .select();

      debugPrint('✅ Delivery person location updated: ($latitude, $longitude)');
      debugPrint('📊 Update result: $result');
    } catch (e) {
      debugPrint('❌ Error updating delivery person location: $e');
      rethrow;
    }
  }

  /// Update delivery person availability status
  static Future<void> updateAvailability(bool isAvailable) async {
    try {
      final supabase = Supabase.instance.client;

      // Get authenticated user
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw UnauthorizedException('User not authenticated');
      }

      // Ensure session is valid before making DB calls
      await AuthService.ensureValidSession();

      // Get internal user ID
      final userResponse =
          await supabase
              .from('users')
              .select('id')
              .eq('user_id', userId)
              .single();

      final internalUserId = userResponse['id'] as int;

      // Get delivery person ID
      final deliveryPersonResponse =
          await supabase
              .from('delivery_persons')
              .select('id')
              .eq('user_id', internalUserId)
              .single();

      final deliveryPersonId = deliveryPersonResponse['id'] as int;

      // Update availability
      await supabase
          .from('delivery_persons')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deliveryPersonId);

      debugPrint('✅ Delivery person availability updated: $isAvailable');
    } catch (e) {
      debugPrint('❌ Error updating delivery person availability: $e');
      rethrow;
    }
  }

  /// Accept a delivery request
  static Future<void> acceptDeliveryRequest(
    int deliveryId,
    int deliveryPersonId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // Use RPC to atomically check status and update
      await supabase.rpc(
        'accept_delivery_request',
        params: {
          'p_delivery_id': deliveryId,
          'p_delivery_person_id': deliveryPersonId,
        },
      );

      debugPrint(
        '✅ Delivery request accepted: $deliveryId by $deliveryPersonId',
      );
    } catch (e) {
      debugPrint('❌ Error accepting delivery request: $e');
      rethrow;
    }
  }

  /// Propose a new price for a delivery request
  static Future<void> proposePrice(
    int deliveryId,
    int deliveryPersonId,
    double proposedPrice,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      // Use RPC to propose price
      await supabase.rpc(
        'propose_delivery_price',
        params: {
          'p_delivery_id': deliveryId,
          'p_delivery_person_id': deliveryPersonId,
          'p_proposed_price': proposedPrice,
        },
      );

      debugPrint('✅ Price proposed: \$$proposedPrice for delivery $deliveryId');
    } catch (e) {
      debugPrint('❌ Error proposing price: $e');
      rethrow;
    }
  }

  /// Get delivery history
  static Future<List<DeliveryRequest>> getDeliveryHistory({
    List<String>? statuses,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Get authenticated user
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw UnauthorizedException('User not authenticated');
      }

      // Get delivery person ID
      final deliveryPersonId = await AuthService.getDeliveryPersonId();
      if (deliveryPersonId == null) {
        throw Exception('Delivery person profile not found');
      }

      var query = supabase
          .from('delivery_requests')
          .select('''
            *,
            passenger:passengers!delivery_requests_passenger_id_fkey(
              user:users!passengers_user_id_fkey(*)
            )
          ''')
          .eq('delivery_person_id', deliveryPersonId);

      if (statuses != null && statuses.isNotEmpty) {
        query = query.inFilter('status', statuses);
      }

      // Order by updated_at descending
      final response = await query.order('updated_at', ascending: false);

      return (response as List)
          .map((json) => DeliveryRequest.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching delivery history: $e');
      rethrow;
    }
  }
}
