import 'package:drivio_app/driver/services/change_status.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverStatusProvider extends ChangeNotifier {
  String _driverStatus = 'inactive';
  String? _statusMessage = "";

  String get driverStatus => _driverStatus;
  String? get statusMessage => _statusMessage;

  DriverStatusProvider() {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _driverStatus = prefs.getString("status") ?? 'inactive';

    notifyListeners();
  }

  Future<void> toggleStatus(String status) async {
    if (status == 'active') {
      _statusMessage = await ChangeStatus().goOnline();
    } else if (status == 'on_trip') {
      _statusMessage = await ChangeStatus().onTrip();
    } else {
      _statusMessage = await ChangeStatus().goOffline();
    }

    _driverStatus = status;
    notifyListeners();
  }
}
