import 'package:drivio_app/passenger/models/passenger.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverPassengerService {
  static Future<Passenger> getPassenger(int passengerId) async {
    try {
      debugPrint('🔍 Fetching passenger with ID: $passengerId');

      // Query Supabase with join to get user data
      final response =
          await Supabase.instance.client
              .from('passengers')
              .select('''
          *,
          user:users!passengers_user_id_fkey(*)
        ''')
              .eq('id', passengerId)
              .single(); // Use .single() instead of .maybeSingle() to throw if not found

      debugPrint('✅ Passenger data retrieved: $response');

      // Parse and return the Passenger object
      return Passenger.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase error: ${e.message}');

      // Handle specific error codes
      if (e.code == 'PGRST116') {
        // No rows returned
        throw Exception('Passenger with ID $passengerId not found');
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
