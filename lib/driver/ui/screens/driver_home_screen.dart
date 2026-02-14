import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/destination_provider.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'driver_map_view.dart';
import '../widgets/driver_top_bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:drivio_app/common/widgets/gps_button.dart';
import 'package:drivio_app/driver/ui/widgets/driver_control_panel.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverProvider>(context, listen: false).getDriver(context);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final driver = driverProvider.currentDriver;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Map Layer (Bottom)
          MapView(mapController: _mapController),

          // 2. Top Bar (Floating)
          DriverTopBar(
            currentLocation:
                driver?.location != null
                    ? LatLng(
                      driver!.location!.latitude!,
                      driver.location!.longitude!,
                    )
                    : null,
            onDestinationSelected: (destination, destinationName) {
              debugPrint(
                '📍 Destination selected: $destinationName at $destination',
              );
              Provider.of<DestinationProvider>(
                context,
                listen: false,
              ).setDestination(destination, destinationName);
            },
          ),

          // 3. Map Location Button (Above Control Panel)
          if (driver?.location != null)
            Positioned(
              bottom: 240, // Adjust to be above the collapsed panel
              right: 16,
              child: GPSButton(
                mapController: _mapController,
                currentLocation: LatLng(
                  driver!.location!.latitude!,
                  driver.location!.longitude!,
                ),
              ),
            ),

          // 4. Bottom Control Panel (Draggable Sheet)
          const DriverControlPanel(),
        ],
      ),
    );
  }
}
