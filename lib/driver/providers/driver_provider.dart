import 'dart:async';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/foundation.dart';

class DriverProvider extends ChangeNotifier {
  Driver? _currentDriver;
  Driver? get currentDriver => _currentDriver;

  DriverProvider() {
    getDriver();
  }

  Future<void> getDriver() async {
    _currentDriver = await DriverService.getDriver();
    notifyListeners();
  }
}
