import 'dart:async';
import 'dart:math' as math;

import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/providers/map_reports_provider.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/ui/modals/ride_request_modal.dart';
import 'package:drivio_app/driver/ui/widgets/cancel_trip_widget.dart';
import 'package:drivio_app/driver/utils/map_utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:drivio_app/driver/ui/widgets/go_offline_widget.dart';
import 'package:drivio_app/driver/ui/widgets/go_online_widget.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  List<LatLng> _routePolyline = [];
  final OSRMService _osrmService = OSRMService();
  bool _isLoading = true;
  bool _isMapReady = false; // 🔹 Track if the map is ready
  late DriverLocationProvider locationProvider;
  late RideRequestsProvider rideRequestsProvider;
  late DriverProvider driverProvider;
  Timer? _debounce;

  LatLng? _destination;
  LatLng? _pickup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🔹 Add observer

    locationProvider = Provider.of<DriverLocationProvider>(
      context,
      listen: false,
    );
    rideRequestsProvider = Provider.of<RideRequestsProvider>(
      context,
      listen: false,
    );

    driverProvider = Provider.of<DriverProvider>(context, listen: false);

    // Delay the initialization until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
      _setupLocationListener();
    });
  }

  void _setupLocationListener() {
    locationProvider.addListener(() {
      _debounce?.cancel(); // Cancel previous timer
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(seconds: 1), () async {
        if (mounted &&
            locationProvider.currentLocation != null &&
            _isMapReady) {
          if (rideRequestsProvider.currentRideRequest != null) {
            await _fetchRoute(
              locationProvider.currentLocation!,
              LatLng(
                rideRequestsProvider
                    .currentRideRequest!
                    .pickupLocation
                    .latitude!,
                rideRequestsProvider
                    .currentRideRequest!
                    .pickupLocation
                    .longitude!,
              ),
              LatLng(
                rideRequestsProvider
                    .currentRideRequest!
                    .destinationLocation
                    .latitude!,
                rideRequestsProvider
                    .currentRideRequest!
                    .destinationLocation
                    .longitude!,
              ),
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _debounce?.cancel();
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
      if (driverProvider.currentDriver?.status == DriverStatus.onTrip &&
          rideRequestsProvider.currentRideRequest == null) {
        await rideRequestsProvider.fetchPersistanceRideRequest();
      }

      if (rideRequestsProvider.currentRideRequest != null &&
          locationProvider.currentLocation != null &&
          _isMapReady) {
        _pickup = LatLng(
          rideRequestsProvider.currentRideRequest!.pickupLocation.latitude!,
          rideRequestsProvider.currentRideRequest!.pickupLocation.longitude!,
        );
        _destination = LatLng(
          rideRequestsProvider
              .currentRideRequest!
              .destinationLocation
              .latitude!,
          rideRequestsProvider
              .currentRideRequest!
              .destinationLocation
              .longitude!,
        );

        await _fetchRoute(
          locationProvider.currentLocation!,
          LatLng(
            rideRequestsProvider.currentRideRequest!.pickupLocation.latitude!,
            rideRequestsProvider.currentRideRequest!.pickupLocation.longitude!,
          ),
          LatLng(
            rideRequestsProvider
                .currentRideRequest!
                .destinationLocation
                .latitude!,
            rideRequestsProvider
                .currentRideRequest!
                .destinationLocation
                .longitude!,
          ),
        );
      }
    } catch (e) {
      print('Error initializing map: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getDestinationCoordinates(
    Location pickupLocation,
    Location dropoffLocation,
  ) async {
    if (locationProvider.currentLocation != null) {
      await _fetchRoute(
        locationProvider.currentLocation!,
        LatLng(pickupLocation.latitude!, pickupLocation.longitude!),
        LatLng(dropoffLocation.latitude!, dropoffLocation.longitude!),
      );
      setState(() {
        _pickup = LatLng(pickupLocation.latitude!, pickupLocation.longitude!);
        _destination = LatLng(
          dropoffLocation.latitude!,
          dropoffLocation.longitude!,
        );
      });
    } else {}
  }

  Future<void> _fetchRoute(LatLng driver, LatLng pickup, LatLng dropoff) async {
    // 🔹 Validate coordinates (0.0, 0.0 is invalid)
    if (pickup.latitude == 0.0 ||
        pickup.longitude == 0.0 ||
        dropoff.latitude == 0.0 ||
        dropoff.longitude == 0.0) {
      return;
    }

    try {
      List<LatLng> newPolyline = await _osrmService.getRouteBetweenCoordinates(
        driver,
        pickup,
        dropoff,
      );

      if (newPolyline.isNotEmpty) {
        setState(() => _routePolyline = newPolyline);
      } else {
        debugPrint("OSRM returned an empty route.");
      }
    } catch (e) {
      debugPrint("Failed to fetch route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideRequestsProvider = Provider.of<RideRequestsProvider>(context);
    final reportsProvider = Provider.of<MapReportsProvider>(context);
    final reports = reportsProvider.reports;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (driverProvider.currentDriver?.status == DriverStatus.inactive &&
        !_isLoading) {
      setState(() {
        _routePolyline = [];
        _destination = null;
      });
    }

    return Stack(
      children: [
        driverProvider.currentDriver == null
            ? const Center(child: CircularProgressIndicator())
            : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                initialCenter:
                    locationProvider.currentLocation ??
                    LatLng(37.7749, -122.4194),
                initialZoom: 12,
                onMapReady: () async {
                  // 🔹 Set map as ready
                  setState(() {
                    _isMapReady = true;
                  });

                  // 🔹 Initialize map after it's ready
                  await _initializeMap();
                  _mapController.move(locationProvider.currentLocation!, 15.0);

                  // Listen to ride requests updates
                },
              ),
              children: [
                TileLayer(urlTemplate: MapConstants.tileLayerUrl),
                // Add this new MarkerLayer for reports
                MarkerLayer(
                  markers: MapUtilities().putMarkers(
                    reports
                        .where(
                          (r) =>
                              r.pointLocation != null && r.routePoints == null,
                        )
                        .toList(),
                  ),
                ),
                PolylineLayer(
                  polylines: MapUtilities().drawPolylines(
                    reports.where((r) => r.routePoints != null).toList(),
                  ),
                ),

                Consumer<DriverLocationProvider>(
                  builder: (context, locationProvider, child) {
                    return MarkerLayer(
                      markers: [
                        // Driver's Current Location Marker with Rotation
                        if (locationProvider.currentPosition != null)
                          Marker(
                            point: LatLng(
                              locationProvider.currentPosition!.latitude,
                              locationProvider.currentPosition!.longitude,
                            ),
                            child: Transform.rotate(
                              angle:
                                  (locationProvider.currentPosition!.heading *
                                      math.pi /
                                      180), // Convert degrees to radians
                              child: const Icon(
                                Icons.navigation,
                                size: 30,
                                color: Color.fromARGB(255, 8, 8, 8),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                if (driverProvider.currentDriver?.status ==
                        DriverStatus.active &&
                    rideRequestsProvider.rideRequests.isNotEmpty)
                  // ✅ Ride Request Markers
                  MarkerLayer(
                    markers:
                        rideRequestsProvider.rideRequests.map((rideRequest) {
                          return Marker(
                            point: LatLng(
                              rideRequest.pickupLocation.latitude!,
                              rideRequest.pickupLocation.longitude!,
                            ),
                            child: GestureDetector(
                              onTap: () async {
                                // Get the tapped ride request
                                await _getDestinationCoordinates(
                                  rideRequest
                                      .pickupLocation, // ✅ Pickup location
                                  rideRequest
                                      .destinationLocation, // ✅ Dropoff location (was wrong before)
                                );
                                _mapController.move(
                                  locationProvider.currentLocation!,
                                  15.0 - (rideRequest.distanceKm! / 10),
                                );
                                if (!context.mounted) return;
                                showRideRequestModal(context, rideRequest).then(
                                  (accepted) async {
                                    if (accepted != true) {
                                      setState(() {
                                        _routePolyline = [];
                                        _destination = null;
                                      });
                                    }
                                  },
                                );
                              },
                              child: const Icon(
                                Icons.person_pin_circle,
                                size: 40,
                                color: Colors.orange,
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                // Route Polyline
                if (_routePolyline.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePolyline,
                        color: const Color.fromARGB(255, 9, 9, 9),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
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
                      Marker(
                        point: _pickup!,
                        child: const Icon(
                          Icons.person_pin_circle,
                          size: 40,
                          color: Color.fromARGB(255, 11, 3, 247),
                        ),
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

        if (driverProvider.currentDriver?.status == DriverStatus.active)
          const GoOfflineButton(),
        if (driverProvider.currentDriver?.status == DriverStatus.inactive)
          GoOnlineButton(mapController: _mapController),
        if (driverProvider.currentDriver?.status == DriverStatus.onTrip)
          const CancelTripWidget(),
      ],
    );
  }
}
