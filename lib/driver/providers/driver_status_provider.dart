import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverStatusProvider extends ChangeNotifier {
  bool _driverStatus = false;

  bool get driverStatus => _driverStatus;

  DriverStatusProvider() {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _driverStatus = prefs.getBool("status") ?? false;
    notifyListeners();
  }

  Future<void> toggleStatus(bool status) async {
    _driverStatus = status;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("status", status);
    notifyListeners();
  }
}
