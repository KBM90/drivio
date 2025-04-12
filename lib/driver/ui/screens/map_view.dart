import 'dart:async';

import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/widgets/marker.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:drivio_app/driver/ui/modals/ride_request_modal.dart';
import 'package:drivio_app/driver/ui/widgets/cancel_trip_widget.dart';
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
  List<LatLng> _routePolyline = [];
  final OSRMService _osrmService = OSRMService();
  bool _isLoading = true;
  bool _isMapReady = false; // 🔹 Track if the map is ready
  late DriverLocationProvider locationProvider;
  late RideRequestsProvider rideRequestsProvider;
  late DriverStatusProvider driverStatusProvider;
  Timer? _debounce;

  LatLng? _destination;
  LatLng? _pickup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 🔹 Add observer

    locationProvider = context.read<DriverLocationProvider>();
    rideRequestsProvider = Provider.of<RideRequestsProvider>(
      context,
      listen: false,
    );
    driverStatusProvider = Provider.of<DriverStatusProvider>(
      context,
      listen: false,
    );

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
      _debounce = Timer(const Duration(seconds: 5), () async {
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
      if (driverStatusProvider.driverStatus == "on_trip" &&
          rideRequestsProvider.currentRideRequest == null) {
        await rideRequestsProvider.fetchPersistanceRideRequest();
      }

      if (rideRequestsProvider.currentRideRequest != null &&
          locationProvider.currentLocation != null) {
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
    print("_getDestinationCoordinates()");
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
    } else {
      print("Driver location not available yet.");
    }
  }

  Future<void> _fetchRoute(LatLng driver, LatLng pickup, LatLng dropoff) async {
    print("_fetchRoute()");
    // 🔹 Validate coordinates (0.0, 0.0 is invalid)
    if (pickup.latitude == 0.0 ||
        pickup.longitude == 0.0 ||
        dropoff.latitude == 0.0 ||
        dropoff.longitude == 0.0) {
      print("Invalid pickup/dropoff coordinates.");
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
        print("OSRM returned an empty route.");
      }
    } catch (e) {
      print("Failed to fetch route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverStatusProvider = Provider.of<DriverStatusProvider>(context);
    final rideRequestsProvider = Provider.of<RideRequestsProvider>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (driverStatusProvider.driverStatus == 'inactive' && !_isLoading) {
      setState(() {
        _routePolyline = [];
        _destination = null;
      });
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
              if (locationProvider.currentLocation != null) {
                _mapController.move(locationProvider.currentLocation!, 15.0);
              }

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
              ],
            ),

            if (driverStatusProvider.driverStatus == 'active' &&
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
                              rideRequest.pickupLocation, // ✅ Pickup location
                              rideRequest
                                  .destinationLocation, // ✅ Dropoff location (was wrong before)
                            );
                            _mapController.move(
                              locationProvider.currentLocation!,
                              15.0 - (rideRequest.distanceKm! / 10),
                            );
                            if (!context.mounted) return;
                            showRideRequestModal(context, rideRequest).then((
                              accepted,
                            ) async {
                              if (accepted != true) {
                                setState(() {
                                  _routePolyline = [];
                                  _destination = null;
                                });
                              }
                            });
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

        /// Listen to driverStatus changes
        /*  Consumer<DriverStatusProvider>(
          builder: (context, driverStatusProvider, _) {
            if (driverStatusProvider.driverStatus == 'active') {
              return GoOfflineButton();
            } else if (driverStatusProvider.driverStatus == 'inactive') {
              return GoOnlineButton(mapController: _mapController);
            }

            return CancelTripWidget();
          }
        ),*/
        if (driverStatusProvider.driverStatus == 'active') GoOfflineButton(),
        if (driverStatusProvider.driverStatus == 'inactive')
          GoOnlineButton(mapController: _mapController),
        if (driverStatusProvider.driverStatus == 'on_trip') CancelTripWidget(),
      ],
    );
  }
}
