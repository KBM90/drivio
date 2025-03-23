import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/services/ride_request_services.dart';
import 'package:drivio_app/driver/models/driver.dart';
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

class _MapViewState extends State<MapView> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  LatLng? _destination;
  List<LatLng> _polylinePoints = [];
  final OSRMService _osrmService = OSRMService();
  bool _isLoading = true;
  bool _isMapReady = false; // 🔹 Track if the map is ready
  late DriverLocationProvider locationProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🔹 Add observer

    locationProvider = Provider.of<DriverLocationProvider>(
      context,
      listen: false,
    );

    if (widget.driver?.dropoffLocation != null) {
      _destination = LatLng(
        widget.driver!.dropoffLocation!.latitude,
        widget.driver!.dropoffLocation!.longitude,
      );
    }

    _initializeMap();

    // 🔹 Listen for location updates to recalculate the route
    locationProvider.addListener(() {
      if (mounted && locationProvider.currentLocation != null && _isMapReady) {
        _updateRoute();
        _mapController.move(locationProvider.currentLocation!, 15.0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 🔹 Remove observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔹 Handle lifecycle changes if needed
    if (state == AppLifecycleState.resumed && _isMapReady) {
      _initializeMap();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure the map is initialized after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMapReady) {
        _isMapReady = true;
        _initializeMap();
      }
    });
  }

  Future<void> _initializeMap() async {
    try {
      if (widget.driver?.dropoffLocation != null) {
        await _getDestinationCoordinates(widget.driver!.dropoffLocation!);
      }

      if (locationProvider.currentLocation != null && _destination != null) {
        await _updateRoute(); // Ensures the initial route is set
      }

      if (locationProvider.currentLocation != null && _isMapReady) {
        _mapController.move(locationProvider.currentLocation!, 15.0);
      }
    } catch (e) {
      print('Error initializing map: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRoute() async {
    if (locationProvider.currentLocation != null && _destination != null) {
      _polylinePoints = await _osrmService.getRouteBetweenCoordinates(
        locationProvider.currentLocation!,
        _destination!,
      );
      setState(() {}); // 🔹 Triggers UI update
    }
  }

  Future<void> _getDestinationCoordinates(Location dropoffLocation) async {
    setState(() {
      _destination = LatLng(
        dropoffLocation.latitude,
        dropoffLocation.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverStatusProvider = Provider.of<DriverStatusProvider>(context);
    final locationProvider = Provider.of<DriverLocationProvider>(context);
    final rideRequestsProvider = Provider.of<RideRequestsProvider>(context);

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
            onMapReady: () async {
              // 🔹 Set map as ready
              setState(() {
                _isMapReady = true;
              });

              // 🔹 Initialize map after it's ready
              await _initializeMap();
              // Listen to ride requests updates
            },
          ),
          children: [
            TileLayer(urlTemplate: MapConstants.tileLayerUrl),

            MarkerLayer(
              markers: [
                // Driver's Current Location Marker
                if (locationProvider.currentLocation != null)
                  Marker(
                    point: locationProvider.currentLocation!,
                    child: const Icon(
                      Icons.navigation,
                      size: 40,
                      color: Color.fromARGB(255, 8, 8, 8),
                    ),
                  ),

                // Ride Requests Pickup Markers
                ...rideRequestsProvider.rideRequests.map((rideRequest) {
                  return Marker(
                    point: LatLng(
                      rideRequest.pickupLocation.latitude,
                      rideRequest.pickupLocation.longitude,
                    ),
                    child: const Icon(
                      Icons.person_pin_circle,
                      size: 40,
                      color: Color.fromARGB(255, 93, 2, 2),
                    ),
                  );
                }),
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
                locationProvider.currentLocation;
                if (locationProvider.currentLocation != null && _isMapReady) {
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
