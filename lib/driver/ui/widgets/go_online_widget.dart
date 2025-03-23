import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_status_provider.dart'
    show DriverStatusProvider;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:drivio_app/driver/services/change_status.dart';

class GoOnlineButton extends StatelessWidget {
  final MapController mapController;

  const GoOnlineButton({super.key, required this.mapController});

  @override
  Widget build(BuildContext context) {
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
            try {
              final message = await ChangeStatus().goOnline();
              // ✅ Update location
              locationProvider.currentLocation;
              if (!context.mounted) return;

              // ✅ Update status after a successful request
              Provider.of<DriverStatusProvider>(
                context,
                listen: false,
              ).toggleStatus(true);

              // ✅ Move map to new location
              if (locationProvider.currentLocation != null) {
                print(locationProvider.currentLocation);
                mapController.move(locationProvider.currentLocation!, 15.0);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message!),
                  backgroundColor: Colors.green,
                ),
              );
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
