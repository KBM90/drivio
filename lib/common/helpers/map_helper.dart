import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Helper class for map-related utilities
class MapHelper {
  /// Fits the camera to show the route only if it's not already fully visible.
  /// This prevents unnecessary zooming in when the route is already in view.
  ///
  /// [mapController] - The FlutterMap controller
  /// [routePoints] - List of LatLng points representing the route
  /// [padding] - Optional padding around the route (default: 50.0 on all sides)
  static void fitCameraToRoute(
    MapController mapController,
    List<LatLng> routePoints, {
    EdgeInsets padding = const EdgeInsets.all(50.0),
  }) {
    if (routePoints.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(routePoints);

    // Check if the route is NOT completely visible
    if (!mapController.camera.visibleBounds.contains(bounds.southWest) ||
        !mapController.camera.visibleBounds.contains(bounds.northEast)) {
      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: padding),
      );
    }
  }

  /// Fetches route between two points and returns the polyline and distance.
  /// Returns null if the route cannot be fetched or coordinates are invalid.
  ///
  /// [osrmService] - The OSRM service instance
  /// [pickup] - Starting point
  /// [dropoff] - Destination point
  /// [context] - BuildContext for error handling
  ///
  /// Returns a Map with 'polyline' (List<LatLng>) and 'distance' (double),
  /// or null if fetching fails.
  static Future<Map<String, dynamic>?> fetchRoute({
    required dynamic osrmService,
    required LatLng pickup,
    required LatLng dropoff,
    required BuildContext context,
  }) async {
    // Validate coordinates (0.0, 0.0 is invalid)
    if (pickup.latitude == 0.0 ||
        pickup.longitude == 0.0 ||
        dropoff.latitude == 0.0 ||
        dropoff.longitude == 0.0) {
      return null;
    }

    try {
      final polyline = await osrmService.getRouteBetweenPickupAndDropoff(
        pickup,
        dropoff,
        context,
      );

      if (polyline.isNotEmpty) {
        final distance = await osrmService.getDistance(pickup, dropoff);
        return {'polyline': polyline, 'distance': distance};
      }
      return null;
    } catch (e) {
      debugPrint("Failed to fetch route: $e");
      return null;
    }
  }
}
