import 'dart:async';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/models/map_report.dart';
import 'package:drivio_app/driver/services/map_report_services.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapReportsProvider extends ChangeNotifier {
  List<MapReport> _reports = [];
  List<MapReport> _userReports = [];

  String? _errorMessage;
  bool _isLoading = false;

  Timer? _refreshTimer;
  LatLng? _lastRefreshLocation;
  static const double _refreshDistanceThreshold = 500; // meters

  List<MapReport> get reports => _reports;
  List<MapReport> get userReports => _userReports;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  MapReportsProvider() {
    getReportsWithinRadius();
    _startPeriodicRefresh();
  }

  Future<void> getReportsWithinRadius() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notify immediately when loading starts

    try {
      final currentLocation = await GeolocatorHelper.getCurrentLocation();

      // Check if we should refresh based on distance moved
      if (_lastRefreshLocation != null && currentLocation != null) {
        final distance = Geolocator.distanceBetween(
          _lastRefreshLocation!.latitude,
          _lastRefreshLocation!.longitude,
          currentLocation.latitude,
          currentLocation.longitude,
        );

        if (distance < _refreshDistanceThreshold) {
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      _reports = await MapReportService.getReportsWithinRadius();

      if (currentLocation != null) {
        _lastRefreshLocation = currentLocation;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ MapReportsProvider Error fetching reports: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startPeriodicRefresh() {
    // Refresh reports every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      getReportsWithinRadius();
    });
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
