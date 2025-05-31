import 'dart:async';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/change_status.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/foundation.dart';

class DriverProvider extends ChangeNotifier {
  Driver? _currentDriver;
  Driver? get currentDriver => _currentDriver;

  String? _statusMessage = "";

  String? get statusMessage => _statusMessage;

  DriverProvider() {
    getDriver();
  }

  Future<void> getDriver() async {
    _currentDriver = await DriverService.getDriver();
    notifyListeners();
  }

  Future<void> toggleStatus(String status) async {
    switch (status) {
      case 'active':
        _statusMessage = await ChangeStatus().goOnline();
        _currentDriver?.status = DriverStatus.active;
        break;
      case 'on_trip':
        _statusMessage = await ChangeStatus().onTrip();
        _currentDriver?.status = DriverStatus.onTrip;
        break;
      case 'inactive':
        _statusMessage = await ChangeStatus().goOffline();
        _currentDriver?.status = DriverStatus.inactive;
        break;
    }

    notifyListeners();
  }

  Future<void> stopNewRequsts() async {
    try {
      // Check if _currentDriver is null
      if (_currentDriver == null) {
        print('Error: Current driver is not loaded.');
        return; // Or throw an exception, depending on your needs
      }

      String message = await DriverService.stopNewRequsts();
      if (message == 'Driver is now unavailable for new requests.') {
        _currentDriver!.acceptNewRequest = 0;
      } else {
        _currentDriver!.acceptNewRequest = 1;
      }
      notifyListeners();
    } catch (e) {
      print('Error stopping new requests: $e');
      // Optionally, notify the UI of the error (e.g., show a snackbar)
      // For now, we don't update _currentDriver if the request fails
    }
  }

  Future<void> acceptNewRequests() async {
    try {
      // Check if _currentDriver is null
      if (_currentDriver == null) {
        print('Error: Current driver is not loaded.');
        return; // Or throw an exception, depending on your needs
      }

      String message = await DriverService.acceptNewRequests();
      if (message == 'Driver is now available for new requests.') {
        _currentDriver!.acceptNewRequest = 1;
      } else {
        _currentDriver!.acceptNewRequest = 0;
      }
      notifyListeners();
    } catch (e) {
      print('Error stopping new requests: $e');
      // Optionally, notify the UI of the error (e.g., show a snackbar)
      // For now, we don't update _currentDriver if the request fails
    }
  }
}
