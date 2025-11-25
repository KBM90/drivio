import 'package:drivio_app/passenger/models/passenger.dart';
import 'package:drivio_app/passenger/services/passenger_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerProvider extends ChangeNotifier {
  Passenger? _currentPassenger;
  Passenger? get currentPassenger => _currentPassenger;

  // Alternative: Get current authenticated user's passenger profile
  Future getCurrentPassenger() async {
    try {
      final passenger = await PassengerService.getCurrentPassenger();
      _currentPassenger = passenger;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching passenger: $e');
      return null;
    }
  }

  // Bonus: Get passenger ID only (lightweight query)
  static Future<int?> getPassengerId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        return null;
      }

      final response =
          await Supabase.instance.client
              .from('passengers')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

      return response?['id'] as int?;
    } catch (e) {
      debugPrint('❌ Error fetching passenger ID: $e');
      return null;
    }
  }
}
