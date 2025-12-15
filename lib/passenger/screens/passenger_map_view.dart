import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/common/constants/transport_constants.dart';
import 'package:drivio_app/common/helpers/error_handler.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
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
    // 🔹 Validate coordinates (0.0, 0.0 is invalid)
    if (pickup.latitude == 0.0 ||
        pickup.longitude == 0.0 ||
        dropoff.latitude == 0.0 ||
        dropoff.longitude == 0.0) {
      return;
    }

    try {
      List<LatLng> newPolyline = await _osrmService
          .getRouteBetweenPickupAndDropoff(pickup, dropoff, context);

      if (newPolyline.isNotEmpty && mounted) {
        final distance = await _osrmService.getDistance(pickup, dropoff);

        setState(() {
          _routePolyline = newPolyline;
          _distance = distance;
        });
        _fitCameraToRoute(newPolyline);
      } else {
        if (newPolyline.isEmpty && mounted) {
          handleAppError(context, 'No route found');
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch route: $e");
      if (mounted) {
        handleAppError(context, 'Failed to fetch route');
      }
    }
  }

  void _fitCameraToRoute(List<LatLng> routePoints) {
    if (routePoints.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(routePoints);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50.0)),
    );
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
          // Add this as a child in your Stack containing the map
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00FF00), width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Los Santos',
                    style: TextStyle(
                      color: const Color(0xFF00FF00),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier', // Retro font
                    ),
                  ),
                  Text(
                    '12:00',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentLocation ??
                  LatLng(
                    31.7917, // latitude (rough center of Morocco)
                    -7.0926, // longitude (rough center of Morocco)
                  ), // London center
              initialZoom: 5.5,
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
                      color: const Color.fromARGB(255, 3, 243, 27),
                      strokeWidth: 2,
                    ),
                  ],
                ),
              //Route from driver to Pickup
              if (_routePolylineDriverToPickup.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePolylineDriverToPickup,
                      color: const Color.fromARGB(255, 9, 107, 245),
                      strokeWidth: 2,
                    ),
                  ],
                ),
            ],
          ),

          // Search Bar Positioned on top
          if (_destination == null)
            Positioned(
              bottom: 60,
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

                    if (pickup != null && destination != null && mounted) {
                      setState(() {
                        _pickupLocation = pickup;
                        _destination = destination;
                      });
                      await _fetchRoute(pickup, destination);
                    }
                  }
                },
                child: const SearchBarWidget(),
              ),
            ),
          // Confirm Destination Button
          if (_destination != null && _confirmed == false)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 233, 96, 4),
                ),
                onPressed: () {
                  // Trigger trip request logic here
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder:
                        (_) => FinalRideConfirmationModal(
                          distance: _distance,
                          initialTransport: TransportConstants.transports.first,
                          onConfirm: (
                            price,
                            transportType,
                            paymentMethod,
                          ) async {
                            if (mounted) {
                              setState(() {
                                _confirmed = true;
                              });
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Publishing ride request ...'),
                                duration: const Duration(seconds: 5),
                              ),
                            );

                            if (_currentLocation == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Current location not available. Please wait...',
                                  ),
                                ),
                              );
                              return;
                            }

                            final message = await rideRequestProvider
                                .createRequest(
                                  pickup: _currentLocation!,
                                  destination: _destination!,
                                  transportTypeId: transportType.id,
                                  price: price,
                                  paymentMethodId: paymentMethod.id,
                                );

                            // Show the message in a SnackBar
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message['message']),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.passengerHome,
                              );
                            }
                          },
                        ),
                  );
                },
                child: const Text(
                  "Confirm Destination",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          // Reset Destination Button
          if (_destination != null)
            Positioned(
              top: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'resetDestination',
                mini: true,
                backgroundColor: Colors.white,
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
                child: const Icon(Icons.clear, color: Colors.red),
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
