import 'package:drivio_app/common/models/delivery_request.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/delivery_person/models/delivery_person.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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

  /// Get the customer's active delivery request (pending or in-progress)
  static Future<DeliveryRequest?> getActiveDeliveryRequest() async {
    try {
      final passengerId = await AuthService.getPassengerId();
      if (passengerId == null) {
        throw Exception('Passenger profile not found');
      }

      final response =
          await Supabase.instance.client
              .from('delivery_requests')
              .select('''
            *,
            delivery_person:delivery_person_id(
              *,
              user:user_id(
                id,
                name,
                phone,
                profile_image_path
              )
            )
          ''')
              .eq('passenger_id', passengerId)
              .inFilter('status', [
                'pending',
                'accepted',
                'picking_up',
                'picked_up',
                'delivering',
              ])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (response == null) {
        return null;
      }

      return DeliveryRequest.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching active delivery request: $e');
      rethrow;
    }
  }

  /// Get a specific delivery request by ID
  /// Uses RPC to bypass RLS policies
  static Future<DeliveryRequest> getDeliveryRequestById(int deliveryId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_delivery_request_by_id',
        params: {'p_delivery_id': deliveryId},
      );

      if (response == null) {
        throw Exception('Delivery request not found');
      }

      return DeliveryRequest.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Error fetching delivery request: $e');
      rethrow;
    }
  }

  /// Listen to real-time updates for a specific delivery request
  static Stream<DeliveryRequest> listenToDeliveryUpdates(int deliveryId) {
    return Supabase.instance.client
        .from('delivery_requests')
        .stream(primaryKey: ['id'])
        .eq('id', deliveryId)
        .map((data) {
          if (data.isEmpty) {
            throw Exception('Delivery request not found');
          }
          return DeliveryRequest.fromJson(data.first);
        });
  }

  /// Get delivery person's current location
  static Future<DeliveryPerson?> getDeliveryPersonWithLocation(
    int deliveryPersonId,
  ) async {
    try {
      final response =
          await Supabase.instance.client
              .from('delivery_persons')
              .select('''
            *,
            user:user_id(
              id,
              name,
              phone,
              profile_image_path
            )
          ''')
              .eq('id', deliveryPersonId)
              .single();

      return DeliveryPerson.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error fetching delivery person: $e');
      rethrow;
    }
  }

  /// Listen to delivery person location updates
  static Stream<DeliveryPerson> listenToDeliveryPersonLocation(
    int deliveryPersonId,
  ) {
    return Supabase.instance.client
        .from('delivery_persons')
        .stream(primaryKey: ['id'])
        .eq('id', deliveryPersonId)
        .map((data) {
          if (data.isEmpty) {
            throw Exception('Delivery person not found');
          }
          return DeliveryPerson.fromJson(data.first);
        });
  }

  /// Get nearby pending delivery requests based on delivery person's location
  /// Uses PostGIS for accurate distance calculations and respects delivery person's range preference
  static Future<List<DeliveryRequest>> getNearbyDeliveryRequests(
    LatLng deliveryPersonLocation,
  ) async {
    try {
      // Get the delivery person's ID
      final deliveryPersonId = await AuthService.getDeliveryPersonId();

      // Create a PostGIS POINT geometry string
      // Format: SRID=4326;POINT(longitude latitude) - note the order!
      final deliveryPersonLocationGeometry =
          'SRID=4326;POINT(${deliveryPersonLocation.longitude} ${deliveryPersonLocation.latitude})';

      // Call RPC to get complete delivery data with joins
      // This function uses SECURITY DEFINER to bypass RLS policies
      final List<dynamic> rpcResponse = await Supabase.instance.client.rpc(
        'get_nearby_pending_deliveries',
        params: {
          'delivery_person_location': deliveryPersonLocationGeometry,
          'p_delivery_person_id':
              deliveryPersonId, // Pass delivery_person_id to use their range preference
        },
      );

      if (rpcResponse.isEmpty) {
        return [];
      }

      // Convert to DeliveryRequest objects directly from RPC response
      return (rpcResponse).map((json) {
        // Create a mutable copy of the JSON
        final Map<String, dynamic> deliveryData = Map<String, dynamic>.from(
          json as Map,
        );

        var request = DeliveryRequest.fromJson(deliveryData);

        // Calculate total distance: Driver -> Pickup -> Delivery
        if (request.pickupLocation?.latitude != null &&
            request.pickupLocation?.longitude != null &&
            request.deliveryLocation?.latitude != null &&
            request.deliveryLocation?.longitude != null) {
          final Distance distance = const Distance();

          final double distToPickup = distance.as(
            LengthUnit.Kilometer,
            deliveryPersonLocation,
            LatLng(
              request.pickupLocation!.latitude!,
              request.pickupLocation!.longitude!,
            ),
          );

          final double distToDropoff = distance.as(
            LengthUnit.Kilometer,
            LatLng(
              request.pickupLocation!.latitude!,
              request.pickupLocation!.longitude!,
            ),
            LatLng(
              request.deliveryLocation!.latitude!,
              request.deliveryLocation!.longitude!,
            ),
          );

          request = request.copyWith(distanceKm: distToPickup + distToDropoff);
        }

        return request;
      }).toList();
    } catch (e) {
      debugPrint('❌ Error fetching nearby delivery requests: $e');
      return [];
    }
  }

  /// Get all available (pending) delivery requests for delivery persons
  /// Get all available (pending) delivery requests for delivery persons
  static Future<List<DeliveryRequest>> getAvailableDeliveryRequests() async {
    try {
      final response = await Supabase.instance.client
          .from('delivery_requests')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => DeliveryRequest.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching available delivery requests: $e');
      rethrow;
    }
  }

  /// Cancel a delivery request (only if not yet picked up)
  static Future<void> cancelDeliveryRequest(int deliveryId) async {
    try {
      final request = await getDeliveryRequestById(deliveryId);

      // Only allow cancellation if not yet picked up
      if (request.status != 'pending' &&
          request.status != 'accepted' &&
          request.status != 'picking_up') {
        throw Exception('Cannot cancel delivery that is already picked up');
      }

      await Supabase.instance.client
          .from('delivery_requests')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deliveryId);

      debugPrint('✅ Delivery request cancelled: $deliveryId');
    } catch (e) {
      debugPrint('❌ Error cancelling delivery request: $e');
      rethrow;
    }
  }

  /// Accept the proposed price from delivery person
  static Future<void> acceptProposedPrice(int deliveryId) async {
    try {
      final supabase = Supabase.instance.client;

      // Use RPC to accept proposed price
      await supabase.rpc(
        'accept_proposed_price',
        params: {'p_delivery_id': deliveryId},
      );

      debugPrint('✅ Proposed price accepted for delivery: $deliveryId');
    } catch (e) {
      debugPrint('❌ Error accepting proposed price: $e');
      rethrow;
    }
  }

  /// Reject the proposed price from delivery person
  static Future<void> rejectProposedPrice(int deliveryId) async {
    try {
      final supabase = Supabase.instance.client;

      // Use RPC to reject proposed price
      await supabase.rpc(
        'reject_proposed_price',
        params: {'p_delivery_id': deliveryId},
      );

      debugPrint('✅ Proposed price rejected for delivery: $deliveryId');
    } catch (e) {
      debugPrint('❌ Error rejecting proposed price: $e');
      rethrow;
    }
  }
}
