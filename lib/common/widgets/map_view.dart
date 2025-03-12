import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:drivio_app/driver/screens/widgets/go_offline_widget.dart';
import 'package:drivio_app/driver/screens/widgets/go_online_widget.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    // Fetch initial location when the map loads
    Future.delayed(Duration.zero, () async {
      final locationProvider = Provider.of<DriverLocationProvider>(
        context,
        listen: false,
      );
      await locationProvider.updateLocation();

      // ✅ Move the map to the new location
      if (locationProvider.currentLocation != null) {
        _mapController.move(locationProvider.currentLocation!, 15.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverStatusProvider = Provider.of<DriverStatusProvider>(context);
    final locationProvider = Provider.of<DriverLocationProvider>(context);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            initialCenter:
                locationProvider.currentLocation ??
                LatLng(37.7749, -122.4194), // Default: San Francisco
            initialZoom: 13,
          ),
          children: [
            TileLayer(urlTemplate: MapConstants.tileLayerUrl),
            if (locationProvider.currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: locationProvider.currentLocation!,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.car_crash, color: Colors.red, size: 40),
                  ),
                ],
              ),
          ],
        ),

        /// GPS Button (Bottom Right)
        Positioned(
          bottom: 80,
          right: 2,
          child: FloatingActionButton(
            onPressed: () async {
              await locationProvider.updateLocation(); // 🔄 Update location
              // ✅ Move the map to the new location
              if (locationProvider.currentLocation != null) {
                _mapController.move(locationProvider.currentLocation!, 15.0);
              }
            },
            backgroundColor: Colors.white,
            elevation: 3,
            mini: true,
            shape: CircleBorder(),
            child: Icon(Icons.my_location, color: Colors.black, size: 20),
          ),
        ),

        /// Listen to driverStatus changes
        driverStatusProvider.driverStatus
            ? GoOfflineButton()
            : GoOnlineButton(mapController: _mapController),
      ],
    );
  }
}
