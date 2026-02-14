import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GPSButton extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentLocation;
  final double zoomLevel;

  const GPSButton({
    super.key,
    required this.mapController,
    required this.currentLocation,
    this.zoomLevel = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        if (currentLocation != null) {
          try {
            mapController.move(currentLocation!, zoomLevel);
          } catch (e) {
            debugPrint('Error updating location: $e');
          }
        } else {
          debugPrint('Current location is null');
        }
      },
      backgroundColor: Colors.white,
      elevation: 3,
      mini: true,
      shape: const CircleBorder(),
      child: const Icon(Icons.my_location, color: Colors.black, size: 20),
    );
  }
}
