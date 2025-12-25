import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Provider to manage destination selection from search
class DestinationProvider with ChangeNotifier {
  LatLng? _selectedDestination;
  String? _destinationName;
  List<LatLng> _routeToDestination = [];

  LatLng? get selectedDestination => _selectedDestination;
  String? get destinationName => _destinationName;
  List<LatLng> get routeToDestination => _routeToDestination;

  bool get hasDestination => _selectedDestination != null;

  /// Set a new destination from search
  void setDestination(LatLng destination, String name) {
    _selectedDestination = destination;
    _destinationName = name;
    notifyListeners();
  }

  /// Update the route polyline to the destination
  void setRoute(List<LatLng> route) {
    _routeToDestination = route;
    notifyListeners();
  }

  /// Clear the current destination and route
  void clearDestination() {
    _selectedDestination = null;
    _destinationName = null;
    _routeToDestination = [];
    notifyListeners();
  }
}
