import 'package:drivio_app/common/models/map_report.dart';
import 'package:drivio_app/driver/services/map_report_services.dart';
import 'package:flutter/material.dart';

class MapReportsProvider extends ChangeNotifier {
  List<MapReport> _reports = [];
  List<MapReport> _userReports = [];

  String? _errorMessage;
  bool _isLoading = false;

  List<MapReport> get reports => _reports;
  List<MapReport> get userReports => _userReports;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  MapReportsProvider() {
    getReportsWithinRadius();
  }

  Future<void> getReportsWithinRadius() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      _reports = await MapReportService.getReportsWithinRadius();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<MapReport>> getUserReports() async {
    _isLoading = true;
    _errorMessage = null;

    try {
      _userReports = await MapReportService.getUserMapReports();
      return _userReports;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error fetching reports: $e');
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
