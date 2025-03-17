import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/driver_dropoff_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:drivio_app/driver/ui/widgets/go_offline_widget.dart';
import 'package:drivio_app/driver/ui/widgets/go_online_widget.dart';

class MapView extends StatefulWidget {
  final Driver? driver;

  const MapView({super.key, this.driver});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  LatLng? _destination;
  List<LatLng> _polylinePoints = [];
  final OSRMService _osrmService = OSRMService();
  bool _isLoading = true;
  late DriverLocationProvider locationProvider; // Define as a field
  late DriverDropOffLocationProvider driverDropOffLocationProvider;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final locationProvider = Provider.of<DriverLocationProvider>(
        context,
        listen: false,
      );
      driverDropOffLocationProvider =
          Provider.of<DriverDropOffLocationProvider>(context, listen: false);

      await locationProvider.updateLocation();

      if (widget.driver?.dropoffLocation != null) {
        await _getDestinationCoordinates(widget.driver!.dropoffLocation!);
      }

      if (locationProvider.currentLocation != null && _destination != null) {
        _polylinePoints = await _osrmService.getRouteBetweenCoordinates(
          locationProvider.currentLocation!,
          _destination!,
        );
      }

      if (locationProvider.currentLocation != null) {
        _mapController.move(locationProvider.currentLocation!, 15.0);
      }

      driverDropOffLocationProvider.addListener(() {
        if (mounted && driverDropOffLocationProvider.dropoffLocation != null) {
          setState(() {
            _destination =
                driverDropOffLocationProvider.dropoffLocation ?? null;
          });

          _updateRoute();
        }
      });
    } catch (e) {
      print('Error initializing map: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateRoute() async {
    if (locationProvider.currentLocation != null && _destination != null) {
      _polylinePoints = await _osrmService.getRouteBetweenCoordinates(
        locationProvider.currentLocation!,
        _destination!,
      );
      setState(() {});
    }
  }

  Future<void> _getDestinationCoordinates(Location dropoffLocation) async {
    try {
      setState(() {
        _destination = LatLng(
          dropoffLocation.latitude,
          dropoffLocation.longitude,
        );
      });
    } catch (e) {
      print('Error setting destination coordinates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverStatusProvider = Provider.of<DriverStatusProvider>(context);
    final locationProvider = Provider.of<DriverLocationProvider>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
            initialCenter:
                locationProvider.currentLocation ?? LatLng(37.7749, -122.4194),
            initialZoom: 13,
          ),
          children: [
            TileLayer(urlTemplate: MapConstants.tileLayerUrl),

            // Current Location Marker
            if (locationProvider.currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: locationProvider.currentLocation!,
                    child: const Icon(
                      Icons.navigation,
                      size: 40,
                      color: Color.fromARGB(255, 8, 8, 8),
                    ),
                  ),
                ],
              ),

            // Destination Marker
            if (_destination != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _destination!,
                    child: const Icon(
                      Icons.location_pin,
                      size: 40,
                      color: Color.fromARGB(255, 11, 3, 247),
                    ),
                  ),
                ],
              ),

            // Route Polyline
            if (_polylinePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polylinePoints,
                    color: const Color.fromARGB(255, 9, 9, 9),
                    strokeWidth: 4,
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
              try {
                await locationProvider.updateLocation();
                if (locationProvider.currentLocation != null) {
                  _mapController.move(locationProvider.currentLocation!, 15.0);
                  final newPolylinePoints = await _osrmService
                      .getRouteBetweenCoordinates(
                        locationProvider.currentLocation!,
                        _destination!,
                      );
                  // Recalculate polyline if destination exists
                  if (_destination != null) {
                    setState(() {
                      _polylinePoints = newPolylinePoints;
                    });
                  }
                }
              } catch (e) {
                print('Error updating location: $e');
                // Optionally, show a snackbar or dialog to inform the user
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
