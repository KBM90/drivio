import 'package:drivio_app/driver/services/passenger_services.dart';
import 'package:drivio_app/passenger/models/passenger.dart';
import 'package:flutter/foundation.dart';

class PassengerProvider extends ChangeNotifier {
  Passenger? _currentPassenger;
  Passenger? get currentPassenger => _currentPassenger;

  Future<void> getPassenger(int passengerId) async {
    try {
      final passenger = await PassengerService.getPassenger(passengerId);
      _currentPassenger = passenger;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching passenger: $e');
      }
    }
  }
}
