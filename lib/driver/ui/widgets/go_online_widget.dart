import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';

import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

class GoOnlineButton extends StatelessWidget {
  final MapController mapController;

  const GoOnlineButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final rideRequestsProvider = Provider.of<RideRequestsProvider>(context);

    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          heroTag: "go_button", // Unique hero tag
          onPressed: () async {
            final locationProvider = Provider.of<DriverLocationProvider>(
              context,
              listen: false,
            );
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            try {
              // 1. First check if we still have a valid context
              if (!context.mounted) return;

              // 2. Update status
              await driverProvider.toggleStatus('active');

              // 3. Fetch ride requests
              await rideRequestsProvider.fetchRideRequests();
              if (!context.mounted) return;
              // ✅ Move map to new location
              if (locationProvider.currentLocation != null) {
                mapController.move(locationProvider.currentLocation!, 15.0);
              }

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(driverProvider.statusMessage!),
                  backgroundColor: Colors.green,
                ),
              );
              if (rideRequestsProvider.rideRequests.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text("No ride requests found"),
                    backgroundColor: const Color.fromARGB(255, 244, 125, 6),
                  ),
                );
              }
            } catch (e) {
              // ❌ If an error occurs, don't update driverStatus
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          backgroundColor: Colors.blue,
          elevation: 3,
          shape: CircleBorder(),
          child: Text(
            "GO",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
