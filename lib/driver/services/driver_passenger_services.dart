import 'package:drivio_app/passenger/models/passenger.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverPassengerService {
  static Future<Passenger> getPassenger(int userId) async {
    try {
      // Query Supabase with join to get user data
      // Note: We query by user_id, not by passenger id
      final response =
          await Supabase.instance.client
              .from('passengers')
              .select('''
          *,
          user:users(*)
        ''')
              .eq('user_id', userId)
              .maybeSingle(); // Use .maybeSingle() to handle multiple or zero results

      // Check if passenger was found
      if (response == null) {
        throw Exception('Passenger with user ID $userId not found');
      }

      // Parse and return the Passenger object
      return Passenger.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase error: ${e.message}');

      // Handle specific error codes
      if (e.code == 'PGRST116') {
        // No rows returned
        throw Exception('Passenger with user ID $userId not found');
      } else if (e.code == '42501') {
        // Permission denied
        throw Exception('Permission denied. Please check your authentication.');
      }

      throw Exception('Database error: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching passenger: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      throw Exception('Error fetching passenger: $e');
    }
  }
}
