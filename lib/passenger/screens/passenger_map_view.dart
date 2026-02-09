import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/common/constants/transport_constants.dart';
import 'package:drivio_app/common/helpers/error_handler.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/helpers/map_helper.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/providers/device_location_provider.dart';
import 'package:drivio_app/common/widgets/cached_tile_layer.dart';
import 'package:drivio_app/common/widgets/cancel_trip_dialog.dart';
import 'package:drivio_app/passenger/modals/search_bottom_sheet.dart';
import 'package:drivio_app/passenger/modals/final_ride_confirmation_modal.dart';
import 'package:drivio_app/passenger/providers/passenger_ride_request_provider.dart';
import 'package:drivio_app/passenger/widgets/confirm_ride_request_card.dart';
import 'package:drivio_app/passenger/widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class PassengerMapScreen extends StatefulWidget {
  const PassengerMapScreen({super.key});

  @override
  createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  bool _hasExistingRequest = false;
  final MapController _mapController = MapController();
  LatLng? _destination;
  LatLng? _pickupLocation;
  List<LatLng> _routePolyline = [];
  List<LatLng> _routePolylineDriverToPickup = [];
  final OSRMService _osrmService = OSRMService();
  LatLng? _currentLocation;
  double _distance = 0.0;
  double _distanceFromDriverToPickup = 0.0;
  bool? _confirmed = false;
  List<Marker> markers = [];
  String? _instructions; // Add instructions variable

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      DeviceLocationProvider deviceLocationProvider =
          Provider.of<DeviceLocationProvider>(context, listen: false);

      final rideRequestProvider = Provider.of<PassengerRideRequestProvider>(
        context,
        listen: false,
      );

      deviceLocationProvider.addListener(() {
        if (mounted) {
          setState(() {
            _currentLocation = deviceLocationProvider.currentLocation;
          });
          if (_currentLocation != null) {
            _mapController.move(_currentLocation!, 16.0);
          }
        }
      });

      // 🔹 Fetch existing ride request
      await rideRequestProvider.fetchCurrentRideRequest();

      if (rideRequestProvider.currentRideRequest != null && mounted) {
        setState(() {
          _hasExistingRequest = true;
          _destination = GeolocatorHelper.locationToLatLng(
            rideRequestProvider.currentRideRequest?.destinationLocation,
          );
          //here we set _pickupLocation because the _currentLocation(device's location) may change
          _pickupLocation = GeolocatorHelper.locationToLatLng(
            rideRequestProvider.currentRideRequest?.pickupLocation,
          );
        });

        // Draw route to destination
        //here we use _pickupLocation because the _currentLocation(device's location) may change
        await _fetchRoute(_pickupLocation!, _destination!);
        if (rideRequestProvider.currentRideRequest?.status == "accepted") {
          await _fetchRouteFromDriver(
            LatLng(
              (rideRequestProvider
                      .currentRideRequest
                      ?.driver!
                      .location!
                      .latitude!)!
                  .toDouble(),
              (rideRequestProvider
                      .currentRideRequest
                      ?.driver!
                      .location!
                      .longitude!)!
                  .toDouble(),
            ),
            _destination!,
          );
        }
      }
    });
  }

  Future<void> _fetchRoute(LatLng pickup, LatLng dropoff) async {
    final result = await MapHelper.fetchRoute(
      osrmService: _osrmService,
      pickup: pickup,
      dropoff: dropoff,
      context: context,
    );

    if (result != null && mounted) {
      setState(() {
        _routePolyline = result['polyline'] as List<LatLng>;
        _distance = result['distance'] as double;
      });
      MapHelper.fitCameraToRoute(_mapController, result['polyline']);
    } else {
      if (mounted) {
        handleAppError(context, 'No route found');
      }
    }
  }

  Future<void> _fetchRouteFromDriver(
    LatLng driverLocation,
    LatLng pickup,
  ) async {
    // 🔹 Validate coordinates (0.0, 0.0 is invalid)
    if (driverLocation.latitude == 0.0 ||
        driverLocation.longitude == 0.0 ||
        pickup.latitude == 0.0 ||
        pickup.longitude == 0.0) {
      return;
    }

    try {
      List<LatLng> newPolyline = await _osrmService
          .getRouteBetweenPickupAndDropoff(driverLocation, pickup, context);

      if (newPolyline.isNotEmpty && mounted) {
        final distance = await _osrmService.getDistance(driverLocation, pickup);

        setState(() {
          _routePolylineDriverToPickup = newPolyline;
          _distanceFromDriverToPickup = distance;
        });
      } else {
        debugPrint("OSRM returned an empty route.");
      }
    } catch (e) {
      debugPrint("Failed to fetch route: $e");
    }
  }

  void _showConfirmationModal() {
    if (_destination == null || _pickupLocation == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FinalRideConfirmationModal(
            distance: _distance,
            initialTransport: TransportConstants.transports.first,
            initialInstructions: _instructions,
            onConfirm: (price, transport, paymentMethod, instructions) async {
              setState(() {
                _instructions = instructions;
              });

              final rideRequestProvider =
                  Provider.of<PassengerRideRequestProvider>(
                    context,
                    listen: false,
                  );

              try {
                await rideRequestProvider.createRequest(
                  pickup: _pickupLocation!,
                  destination: _destination!,
                  transportTypeId: transport.id,
                  price: price,
                  paymentMethodId: paymentMethod.id,
                  instructions: instructions,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ride request created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  setState(() {
                    _confirmed = true;
                    _hasExistingRequest = true;
                  });

                  // Navigate back to home page
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.passengerHome,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create ride request: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    PassengerRideRequestProvider rideRequestProvider =
        Provider.of<PassengerRideRequestProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true, // Shows the default back button
        elevation: 0, // Optional: remove shadow
        backgroundColor: Colors.white, // Optional: match your theme
        leading: BackButton(color: Colors.black), // Optional: customize color
        toolbarHeight: 28,
      ),
      body: Stack(
        children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentLocation ??
                  LatLng(31.7917, -7.0926), // Default to Casablanca, Morocco
              initialZoom: 15.0,
              onTap: (tapPosition, latLng) async {
                if (!_hasExistingRequest && mounted) {
                  //fetch route from actual location because there is no registred ride request yet
                  //so _pickupLocation will be null

                  setState(() {
                    _destination = latLng;
                  });
                  await _fetchRoute(_currentLocation!, _destination!);
                }
              },
              onMapReady: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => const SearchBottomSheet(),
                );

                if (result != null && result is Map) {
                  final pickup = result['pickup'] as LatLng?;
                  final destination = result['destination'] as LatLng?;

                  if (pickup != null && destination != null && mounted) {
                    setState(() {
                      _pickupLocation = pickup;
                      _destination = destination;
                    });
                    await _fetchRoute(pickup, destination);
                  }
                }
              },
            ),
            children: [
              CachedTileLayer(),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    //marker on current passenger location
                    Marker(
                      point: _currentLocation!,

                      child: Image.asset(
                        'assets/persons/current_location.png',
                        width: 50,
                        height: 50,
                        color: Colors.red,
                      ),
                    ),
                  //marker in pickup location
                  if (rideRequestProvider.currentRideRequest != null)
                    Marker(
                      point: GeolocatorHelper.locationToLatLng(
                        rideRequestProvider.currentRideRequest?.pickupLocation,
                      ),
                      child: Icon(Icons.person_pin_circle, color: Colors.red),
                    ),
                  //marker on destination location
                  if (_destination != null)
                    Marker(
                      point: _destination!,

                      child: Icon(Icons.flag, color: Colors.red),
                    ),
                  //marker on driver location
                  if (_hasExistingRequest &&
                      rideRequestProvider.currentRideRequest?.driver != null)
                    Marker(
                      point: GeolocatorHelper.locationToLatLng(
                        rideRequestProvider
                            .currentRideRequest
                            ?.driver!
                            .location!,
                      ),
                      child: Image.asset(
                        'assets/cars/drivio_car_standard.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                ],
              ),
              // Square arrounf pickup location
              if (rideRequestProvider.currentRideRequest != null)
                PolygonLayer(
                  polygons: [
                    //here we can use _pickupLocation because there is already a registred ride request
                    if (_pickupLocation != null)
                      Polygon(
                        points: OSRMService().squareAround(
                          GeolocatorHelper.locationToLatLng(
                            rideRequestProvider
                                .currentRideRequest
                                ?.pickupLocation,
                          ),
                          40,
                        ), // 10m side length
                        color: Colors.green.withOpacity(0.2),
                        borderColor: Colors.green,
                        borderStrokeWidth: 2,
                      ),
                  ],
                ),
              //Route From passenger's pickup location to destination location
              if (_routePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolyline,
                      color: Colors.black, // Primary route color
                      strokeWidth: 4, // Thicker line
                    ),
                  ],
                ),
              //Route from driver to Pickup
              if (_routePolylineDriverToPickup.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolylineDriverToPickup,
                      color:
                          Colors.blueAccent, // Distinct color for driver path
                      strokeWidth: 4, // Thicker line
                    ),
                  ],
                ),
            ],
          ),

          // 📍 Current Location Button
          Positioned(
            bottom: _destination == null ? 140 : 100,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'currentLocation',
              mini: false,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 16.0);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // 🔍 Modern Search Bar (Floating at bottom)
          if (_destination == null)
            Positioned(
              top: 60, // Moved to top for better UX
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: () async {
                  final result = await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => const SearchBottomSheet(),
                  );

                  if (result != null && result is Map) {
                    final pickup = result['pickup'] as LatLng?;
                    final destination = result['destination'] as LatLng?;
                    final action = result['action'] as String?;

                    if (pickup != null && destination != null && mounted) {
                      setState(() {
                        _pickupLocation = pickup;
                        _destination = destination;
                      });
                      await _fetchRoute(pickup, destination);

                      if (action == 'confirm') {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            _showConfirmationModal();
                          }
                        });
                      }
                    }
                  }
                },
                child: Hero(tag: 'searchBar', child: const SearchBarWidget()),
              ),
            ),

          // ✅ Confirm Destination Button
          if (_destination != null && _confirmed == false)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Primary App Color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _showConfirmationModal,
                    child: const Text(
                      "Confirm Destination",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ❌ Reset Destination Button (Floating top-right)
          if (_destination != null)
            Positioned(
              top: 60,
              left: 16,
              child: FloatingActionButton(
                heroTag: 'resetDestination',
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _destination = null;
                      _routePolyline.clear();
                      _distance = 0.0;
                      _confirmed = false;
                      _hasExistingRequest = false;
                    });
                  }
                },
                child: const Icon(Icons.arrow_back),
              ),
            ),
          if (_hasExistingRequest)
            RideRequestCard(
              status:
                  (rideRequestProvider.currentRideRequest?.status).toString(),
              price: 45.00,
              distanceKm: _distance,
              transportType:
                  (rideRequestProvider.currentRideRequest?.transportType?.name)
                      .toString(),
              driverName:
                  rideRequestProvider.currentRideRequest?.status! == 'accepted'
                      ? '${rideRequestProvider.currentRideRequest?.driver!.user!.name} (${_distanceFromDriverToPickup.toStringAsFixed(2)}km)'
                      : null, // or 'Ahmed El Mansouri'
              onCancel: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                // Add your cancel logic here
                final confirmed = await showCancelTripDialog(context, false);

                if (confirmed == null) return;
                if (confirmed.isNotEmpty) {
                  await rideRequestProvider.cancelRideRequest(confirmed);
                  // Show the message in a SnackBar

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(rideRequestProvider.operationMessage!),
                    ),
                  );
                  if (rideRequestProvider.operationMessage ==
                      'Ride request canceled successfully') {
                    if (!context.mounted) return;
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.passengerHome,
                    );
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
