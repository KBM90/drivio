import 'dart:async';
import 'dart:math' as math;

import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:drivio_app/common/models/location.dart';
import 'package:drivio_app/common/providers/map_reports_provider.dart';
import 'package:drivio_app/common/widgets/cached_tile_layer.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/driver_passenger_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/services/change_status.dart';
import 'package:drivio_app/driver/ui/modals/ride_request_modal.dart';
import 'package:drivio_app/driver/ui/widgets/trip_info_panel.dart';
import 'package:drivio_app/driver/utils/map_utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:drivio_app/driver/ui/widgets/go_offline_widget.dart';
import 'package:drivio_app/driver/ui/widgets/go_online_widget.dart';
import 'package:drivio_app/common/widgets/map_location_button.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  List<LatLng> _routePolyline = [];
  List<LatLng> _routePolylineDriverToPickup = [];
  final OSRMService _osrmService = OSRMService();
  bool _isLoading = true;
  bool _isMapReady = false; // 🔹 Track if the map is ready

  late DriverLocationProvider locationProvider;
  late RideRequestsProvider rideRequestsProvider;
  late DriverProvider driverProvider;
  Timer? _debounce;
  LatLng? _destination;
  LatLng? _pickup;

  bool _hasLoadedRideRequest = false;
  bool _hasInitialFetchDone = false;

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

    // Listen to driver updates to handle async loading
    driverProvider.addListener(_onDriverChanged);

    // Check immediately in case driver is already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onDriverChanged();
    });
  }

  Future<void> _onDriverChanged() async {
    if (!mounted) return;

    final driver = driverProvider.currentDriver;
    if (driver == null) return;

    // Check driver status
    debugPrint("🔍 _onDriverChanged - Driver Status is: ${driver.status}");

    // Fetch current ride request if driver is on_trip (for app restart scenario)
    if (driver.status == DriverStatus.onTrip && !_hasLoadedRideRequest) {
      debugPrint("🔍 Driver is onTrip, calling _loadCurrentRideRequest");
      _hasLoadedRideRequest = true;
      await _loadCurrentRideRequest();
    }

    // Fetch ride requests if driver is active
    if (driver.status == DriverStatus.active &&
        !locationProvider.isLoading &&
        locationProvider.currentLocation != null &&
        !_hasInitialFetchDone) {
      debugPrint("🔍 Driver is active, fetching nearby ride requests");
      _hasInitialFetchDone = true;
      rideRequestsProvider.getNearByRideRequests(
        locationProvider.currentLocation!,
      );
    }
  }

  // Load current ride request from SharedPreferences when app restarts
  Future<void> _loadCurrentRideRequest() async {
    try {
      final currentRideId = await SharedPreferencesHelper().getInt(
        "currentRideId",
      );

      if (currentRideId != null) {
        debugPrint("📍 Loading current ride request: $currentRideId");
        await rideRequestsProvider.fetchRideRequest(currentRideId);

        // Verify the ride request was actually loaded
        if (rideRequestsProvider.currentRideRequest == null) {
          debugPrint("⚠️ Failed to load ride request, going offline");
          await ChangeStatus().goOffline();
          await SharedPreferencesHelper.remove("currentRideId");
        } else {
          debugPrint("✅ Current ride request loaded");
        }
      } else {
        debugPrint("⚠️ No current ride ID found, going offline");
        await ChangeStatus().goOffline();
      }
    } catch (e) {
      debugPrint("❌ Error loading current ride request: $e");
      await ChangeStatus().goOffline();
      await SharedPreferencesHelper.remove("currentRideId");
    }
  }

  void _setupLocationListener() {
    // Listen to DriverLocationProvider for location updates
    locationProvider.addListener(_onLocationUpdate);
  }

  void _onLocationUpdate() {
    _debounce?.cancel();

    if (!mounted || !_isMapReady) return;

    final driverLocation = locationProvider.currentLocation;
    if (driverLocation == null) return;

    _debounce = Timer(const Duration(seconds: 1), () async {
      if (mounted && _isMapReady) {
        try {
          _mapController.move(driverLocation, 15.0);
        } catch (e) {
          debugPrint("⚠️ Error moving map: $e");
        }

        if (rideRequestsProvider.currentRideRequest != null) {
          await _fetchRoute(
            driverLocation,
            LatLng(
              rideRequestsProvider.currentRideRequest!.pickupLocation.latitude!,
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
  }

  @override
  void dispose() {
    _mapController.dispose();
    _debounce?.cancel();
    locationProvider.removeListener(_onLocationUpdate);
    driverProvider.removeListener(_onDriverChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔹 Handle lifecycle changes if needed
    if (state == AppLifecycleState.resumed && _isMapReady) {
      //  _initializeMap();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure the map is initialized after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMapReady) {
        _isMapReady = true;
        // _initializeMap();
      }
    });
  }

  Future<void> _initializeMap() async {
    try {
      // ✅ Get driver location from DriverLocationProvider
      final driverLocation = locationProvider.currentLocation;

      if (driverLocation == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Now use 'location' variable
      // Example: print('Location: ${location.latitude}, ${location.longitude}');

      if (rideRequestsProvider.currentRideRequest != null && _isMapReady) {
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

        await _fetchRoute(driverLocation, _pickup!, _destination!);
      }
    } catch (e) {
      print('Error initializing map: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _getDestinationCoordinates(
    Location pickupLocation,
    Location dropoffLocation,
  ) async {
    // ✅ Get driver location from DriverLocationProvider
    final driverLocation = locationProvider.currentLocation;
    if (driverLocation == null) {
      debugPrint("❌ _getDestinationCoordinates: driverLocation is null");
      return false;
    }

    // Check for null pickup coordinates (destination can be null)
    if (pickupLocation.latitude == null || pickupLocation.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Invalid pickup coordinates for this ride.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Only fetch route if destination is valid
    if (dropoffLocation.latitude != null && dropoffLocation.longitude != null) {
      await _fetchRoute(
        driverLocation,
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
      // No destination, just show pickup
      setState(() {
        _pickup = LatLng(pickupLocation.latitude!, pickupLocation.longitude!);
        _destination = null;
        _routePolyline = [];
        _routePolylineDriverToPickup = [];
      });
    }

    return true;
  }

  Future<void> _fetchRoute(LatLng driver, LatLng pickup, LatLng dropoff) async {
    // 🔹 Validate coordinates (0.0, 0.0 is invalid)
    if (pickup.latitude == 0.0 ||
        pickup.longitude == 0.0 ||
        dropoff.latitude == 0.0 ||
        dropoff.longitude == 0.0) {
      debugPrint("⚠️ Invalid coordinates, skipping route fetch");
      return;
    }

    debugPrint("🗺️ Fetching route: Driver->Pickup and Pickup->Destination");
    try {
      // Fetch Driver -> Pickup
      final driverToPickup = await _osrmService.getRouteBetweenPickupAndDropoff(
        driver,
        pickup,
        context,
      );

      // Fetch Pickup -> Dropoff
      final pickupToDropoff = await _osrmService
          .getRouteBetweenPickupAndDropoff(pickup, dropoff, context);

      debugPrint(
        "✅ Routes fetched: Driver->Pickup (${driverToPickup.length} points), Pickup->Dest (${pickupToDropoff.length} points)",
      );

      if (mounted) {
        setState(() {
          _routePolylineDriverToPickup = driverToPickup;
          _routePolyline = pickupToDropoff;
        });
        debugPrint("✅ Routes stored in state");
        debugPrint(
          "   _routePolylineDriverToPickup length: ${_routePolylineDriverToPickup.length}",
        );
        debugPrint("   _routePolyline length: ${_routePolyline.length}");
      }
    } catch (e) {
      debugPrint("❌ Failed to fetch route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideRequestsProvider = Provider.of<RideRequestsProvider>(context);
    final reportsProvider = Provider.of<MapReportsProvider>(context);
    final reports = reportsProvider.reports;

    if (driverProvider.currentDriver?.status == DriverStatus.inactive &&
        !_isLoading) {
      setState(() {
        _routePolyline = [];
        _destination = null;
      });
    }

    return Stack(
      children: [
        driverProvider.currentDriver == null ||
                locationProvider.currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                // ✅ Use default center until Firestore loads
                initialCenter:
                    locationProvider.currentLocation != null
                        ? LatLng(
                          locationProvider.currentLocation!.latitude,
                          locationProvider.currentLocation!.longitude,
                        )
                        : LatLng(31.7917, -7.0926), // Your default location
                initialZoom: locationProvider.currentLocation != null ? 15 : 6,
                onMapReady: () async {
                  setState(() {
                    _isMapReady = true;
                  });

                  await _initializeMap();

                  // Wait for the map controller to fully initialize
                  await Future.delayed(const Duration(milliseconds: 500));

                  // Setup location listener after map is ready
                  _setupLocationListener();

                  // Wait a bit more before trying to fetch routes
                  await Future.delayed(const Duration(milliseconds: 500));

                  // ✅ Move to driver location initially
                  final driverLocation = locationProvider.currentLocation;
                  if (driverLocation != null && mounted) {
                    // ✅ Fetch routes if there's an active ride request (for app restart)
                    final currentRide = rideRequestsProvider.currentRideRequest;
                    if (currentRide != null &&
                        currentRide.pickupLocation.latitude != null &&
                        currentRide.pickupLocation.longitude != null &&
                        currentRide.destinationLocation.latitude != null &&
                        currentRide.destinationLocation.longitude != null) {
                      debugPrint(
                        "🗺️ Fetching routes for active ride request on map ready",
                      );
                      await _fetchRoute(
                        driverLocation,
                        LatLng(
                          currentRide.pickupLocation.latitude!,
                          currentRide.pickupLocation.longitude!,
                        ),
                        LatLng(
                          currentRide.destinationLocation.latitude!,
                          currentRide.destinationLocation.longitude!,
                        ),
                      );
                    } else {
                      debugPrint(
                        "⚠️ Skipping route fetch: Missing coordinates in ride request",
                      );
                    }
                  }
                },
              ),
              children: [
                CachedTileLayer(),
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

                // Get the driver instance
                // From provider or state
                // ✅ Driver Location Marker from DriverLocationProvider
                Consumer<DriverLocationProvider>(
                  builder: (context, locationProvider, child) {
                    final location = locationProvider.currentLocation;
                    final heading = locationProvider.heading;

                    if (location == null) return const SizedBox.shrink();

                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: location,
                          child: Transform.rotate(
                            angle: (heading * math.pi / 180),
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
                Consumer<DriverProvider>(
                  builder: (context, driverProvider, child) {
                    final isDriverActive =
                        driverProvider.currentDriver?.status ==
                        DriverStatus.active;

                    if (!isDriverActive) {
                      return const SizedBox.shrink();
                    }

                    return PolygonLayer(
                      polygons:
                          rideRequestsProvider.rideRequests
                              .where(
                                (r) =>
                                    r.pickupLocation.latitude != null &&
                                    r.pickupLocation.longitude != null,
                              )
                              .map((rideRequest) {
                                return Polygon(
                                  points: OSRMService().squareAround(
                                    LatLng(
                                      rideRequest.pickupLocation.latitude!,
                                      rideRequest.pickupLocation.longitude!,
                                    ),
                                    40, // 40m side length
                                  ),
                                  color: Colors.green.withOpacity(0.2),
                                  borderColor: Colors.green,
                                  borderStrokeWidth: 2,
                                );
                              })
                              .toList(),
                    );
                  },
                ),
                // ✅ Ride Request Markers
                Consumer2<DriverProvider, RideRequestsProvider>(
                  builder: (
                    context,
                    driverProvider,
                    rideRequestsProvider,
                    child,
                  ) {
                    final isDriverActive =
                        driverProvider.currentDriver?.status ==
                        DriverStatus.active;

                    if (rideRequestsProvider.rideRequests.isNotEmpty &&
                        isDriverActive) {
                      return MarkerLayer(
                        markers:
                            rideRequestsProvider.rideRequests
                                .where(
                                  (r) =>
                                      r.pickupLocation.latitude != null &&
                                      r.pickupLocation.longitude != null,
                                )
                                .map((rideRequest) {
                                  return Marker(
                                    point: LatLng(
                                      rideRequest.pickupLocation.latitude!,
                                      rideRequest.pickupLocation.longitude!,
                                    ),
                                    child: GestureDetector(
                                      onTap: () async {
                                        debugPrint("pickup clicked");
                                        try {
                                          showRideRequestModal(
                                            context,
                                            rideRequest,
                                            rideRequestsProvider,
                                            driverProvider.currentDriver!,
                                          ).then((accepted) async {
                                            debugPrint(
                                              "🏁 Modal closed. Accepted: $accepted",
                                            );
                                            if (accepted != true) {
                                              setState(() {
                                                _routePolyline = [];
                                                _routePolylineDriverToPickup =
                                                    [];
                                                _destination = null;
                                              });
                                            } else {
                                              if (!context.mounted) return;
                                              await driverProvider.toggleStatus(
                                                'on_trip',
                                              );
                                              if (!context.mounted) return;
                                              await Provider.of<
                                                RideRequestsProvider
                                              >(
                                                context,
                                                listen: false,
                                              ).fetchRideRequest(
                                                rideRequest.id,
                                              );
                                              if (!context.mounted) return;
                                              await Provider.of<
                                                DriverPassengerProvider
                                              >(
                                                context,
                                                listen: false,
                                              ).getPassenger(
                                                rideRequest.passenger.id,
                                              );
                                            }
                                          });

                                          final success =
                                              await _getDestinationCoordinates(
                                                rideRequest.pickupLocation,
                                                rideRequest.destinationLocation,
                                              );

                                          // Fetch routes after setting coordinates
                                          if (success &&
                                              locationProvider
                                                      .currentLocation !=
                                                  null &&
                                              rideRequest
                                                      .pickupLocation
                                                      .latitude !=
                                                  null &&
                                              rideRequest
                                                      .pickupLocation
                                                      .longitude !=
                                                  null &&
                                              rideRequest
                                                      .destinationLocation
                                                      .latitude !=
                                                  null &&
                                              rideRequest
                                                      .destinationLocation
                                                      .longitude !=
                                                  null) {
                                            await _fetchRoute(
                                              locationProvider.currentLocation!,
                                              LatLng(
                                                rideRequest
                                                    .pickupLocation
                                                    .latitude!,
                                                rideRequest
                                                    .pickupLocation
                                                    .longitude!,
                                              ),
                                              LatLng(
                                                rideRequest
                                                    .destinationLocation
                                                    .latitude!,
                                                rideRequest
                                                    .destinationLocation
                                                    .longitude!,
                                              ),
                                            );

                                            // Fit camera to show entire route
                                            if (_routePolylineDriverToPickup
                                                    .isNotEmpty &&
                                                _routePolyline.isNotEmpty) {
                                              final allPoints = [
                                                locationProvider
                                                    .currentLocation!,
                                                ..._routePolylineDriverToPickup,
                                                ..._routePolyline,
                                              ];

                                              final bounds =
                                                  LatLngBounds.fromPoints(
                                                    allPoints,
                                                  );
                                              _mapController.fitCamera(
                                                CameraFit.bounds(
                                                  bounds: bounds,
                                                  padding: const EdgeInsets.all(
                                                    50,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e, stack) {
                                          debugPrint(
                                            "❌ Error in pickup onTap: $e",
                                          );
                                          debugPrint(stack.toString());
                                        }
                                      },
                                      child: const Icon(
                                        Icons.person_pin_circle,
                                        size: 40,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
                // Route Driver -> Pickup
                if (_routePolylineDriverToPickup.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePolylineDriverToPickup,
                        color: Colors.blue, // Driver to Pickup in Blue
                        strokeWidth: 4,
                      ),
                    ],
                  ),

                // Route Pickup -> Destination
                if (_routePolyline.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePolyline,
                        color: const Color.fromARGB(
                          255,
                          9,
                          9,
                          9,
                        ), // Pickup to Destination in Black
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
          top:
              MediaQuery.of(context).padding.top +
              MediaQuery.of(context).size.height *
                  0.3, // SafeArea + 2% of screen height
          left: MediaQuery.of(context).size.width * 0.05,
          child: MapLocationButton(
            mapController: _mapController,
            currentLocation: locationProvider.currentLocation,
          ),
        ),
        // ✅ Remove DriverLocationProvider from Consumer2
        Consumer<DriverProvider>(
          builder: (context, driverProvider, child) {
            final status = driverProvider.currentDriver?.status;

            if (status == DriverStatus.active) {
              return const GoOfflineButton();
            } else if (status == DriverStatus.inactive) {
              // ✅ Use DriverLocationProvider for GoOnlineButton
              return Consumer<DriverLocationProvider>(
                builder: (context, locationProvider, child) {
                  final location = locationProvider.currentLocation;

                  if (location == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return GoOnlineButton(
                    mapController: _mapController,
                    driverLocation: location,
                  );
                },
              );
            } else if (status == DriverStatus.onTrip) {
              if (rideRequestsProvider.currentRideRequest != null) {
                return TripInfoPanel(
                  rideRequest: rideRequestsProvider.currentRideRequest!,
                );
              }
              return const SizedBox.shrink();
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }
}
