import 'package:drivio_app/common/models/location.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DistanceProgressWidget extends StatefulWidget {
  final LatLng driverLocation; // Driver's current location
  final Location pickupLocation; // Pickup location from ride request

  const DistanceProgressWidget({
    super.key,
    required this.driverLocation,
    required this.pickupLocation,
  });

  @override
  State<DistanceProgressWidget> createState() => _DistanceProgressWidgetState();
}

class _DistanceProgressWidgetState extends State<DistanceProgressWidget> {
  double initialDistance = 0.0; // Initial distance between driver and pickup
  double currentDistance = 0.0; // Current distance as driver moves
  double progress = 0.0; // Progress value for LinearProgressIndicator

  @override
  void initState() {
    super.initState();
    // Calculate the initial distance when the widget is first created
    calculateInitialDistance();
    // Simulate updating the distance as the driver moves (replace with real-time updates)
    updateDistance();
  }

  // Calculate the initial distance between driver and pickup location
  void calculateInitialDistance() {
    initialDistance = Geolocator.distanceBetween(
      widget.driverLocation.latitude,
      widget.driverLocation.longitude,
      widget.pickupLocation.latitude!,
      widget.pickupLocation.longitude!,
    );
    currentDistance =
        initialDistance; // Initially, current distance = initial distance
  }

  // Update the current distance and progress (e.g., as driver moves)
  void updateDistance() {
    // In a real app, this would be updated in real-time using location updates
    currentDistance = Geolocator.distanceBetween(
      widget.driverLocation.latitude,
      widget.driverLocation.longitude,
      widget.pickupLocation.latitude!,
      widget.pickupLocation.longitude!,
    );

    // Calculate progress as a fraction of the initial distance
    // Progress = (initial distance - current distance) / initial distance
    // This gives a value from 0.0 (driver at start) to 1.0 (driver at pickup)
    setState(() {
      progress = (initialDistance - currentDistance) / initialDistance;
      // Ensure progress stays between 0.0 and 1.0
      progress = progress.clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Takes full available width
      child: LinearProgressIndicator(
        value: progress, // Use the calculated progress value
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }
}
