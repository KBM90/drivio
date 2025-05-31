import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:drivio_app/common/constants/transport_constants.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/helpers/markers_routes_helpers.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/widgets/cancel_trip_dialog.dart';
import 'package:drivio_app/driver/providers/passenger_provider.dart';
import 'package:drivio_app/passenger/modals/search_bottom_sheet.dart';
import 'package:drivio_app/passenger/modals/suggested_price_tansport_modal.dart';
import 'package:drivio_app/passenger/providers/passenger_location_provider.dart';
import 'package:drivio_app/passenger/providers/ride_request_provider.dart';
import 'package:drivio_app/passenger/widgets/ride_request_card.dart';
import 'package:drivio_app/passenger/widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class PassengerMapScreen extends StatelessWidget {
  const PassengerMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PassengerProvider()),
        ChangeNotifierProvider(
          create: (context) => PassengerLocationProvider(),
        ),
        ChangeNotifierProvider(create: (context) => RideRequestProvider()),
      ],
      child: PassengerMapScreenWidget(),
    );
  }
}

class PassengerMapScreenWidget extends StatefulWidget {
  const PassengerMapScreenWidget({super.key});

  @override
  createState() => _PassengerMapScreenWidgetState();
}

class _PassengerMapScreenWidgetState extends State<PassengerMapScreenWidget> {
  bool _hasExistingRequest = false;
  final MapController _mapController = MapController();
  LatLng? _destination;
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
      final locationProvider = Provider.of<PassengerLocationProvider>(
        context,
        listen: false,
      );

      final rideRequestProvider = Provider.of<RideRequestProvider>(
        context,
        listen: false,
      );

      // Listen to user location
      locationProvider.addListener(() {
        _currentLocation = locationProvider.currentLocation;
        if (_currentLocation != null) {
          _mapController.move(_currentLocation!, 16.0);
          addMarkerToMap(_currentLocation!);
        }
      });

      // 🔹 Fetch existing ride request
      await rideRequestProvider.fetchCurrentRideRequest();
      final currentRequest = rideRequestProvider.currentRideRequest;

      if (currentRequest != null) {
        setState(() {
          _hasExistingRequest = true;
          _destination = GeolocatorHelper.locationToLatLng(
            currentRequest.destinationLocation,
          );
          _currentLocation = GeolocatorHelper.locationToLatLng(
            currentRequest.pickupLocation,
          );
        });

        // Draw route to destination
        await _fetchRoute(_currentLocation!, _destination!);
        await _fetchRouteFromDriver(
          LatLng(
            currentRequest.driver!.location!.latitude!,
            currentRequest.driver!.location!.longitude!,
          ),
          _destination!,
        );
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
          .getRouteBetweenPickupAndDropoff(pickup, dropoff);

      if (newPolyline.isNotEmpty) {
        final distance = await _osrmService.getDistance(pickup, dropoff);

        setState(() {
          _routePolyline = newPolyline;
          _distance = distance;
        });
      } else {
        debugPrint("OSRM returned an empty route.");
      }
    } catch (e) {
      debugPrint("Failed to fetch route: $e");
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
          .getRouteBetweenPickupAndDropoff(driverLocation, pickup);

      if (newPolyline.isNotEmpty) {
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

  void addMarkerToMap(LatLng position) async {
    final marker = await MarkersRoutesHelpers().createGifMarker(
      position,
      'assets/others/current_location.gif',
      width: 40,
      height: 40,
    );
    setState(() {
      markers.add(marker);
    });
  }

  @override
  Widget build(BuildContext context) {
    RideRequestProvider _rideRequestProvider = Provider.of<RideRequestProvider>(
      context,
      listen: false,
    );
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
              initialCenter: LatLng(51.509865, -0.118092), // London center
              initialZoom: 5.5,
              onTap: (tapPosition, latLng) async {
                if (_hasExistingRequest) return;

                setState(() {
                  _destination = latLng;
                });
                await _fetchRoute(_currentLocation!, _destination!);
              },
              onMapReady:
                  () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => const SearchBottomSheet(),
                  ),
            ),
            children: [
              TileLayer(urlTemplate: MapConstants.tileLayerUrl),
              MarkerLayer(
                markers: [
                  if (Provider.of<PassengerLocationProvider>(
                        context,
                      ).currentLocation !=
                      null)
                    //marker on current passenger location
                    // markers[0],
                    Marker(
                      point:
                          Provider.of<PassengerLocationProvider>(
                            context,
                          ).currentLocation!,
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/others/current_location.gif',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  //marker in pickup location
                  if (_rideRequestProvider.currentRideRequest != null)
                    Marker(
                      point: GeolocatorHelper.locationToLatLng(
                        _rideRequestProvider.currentRideRequest!.pickupLocation,
                      ),
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/persons/person_raising_hand.png',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  //marker on destination location
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 40,
                      height: 40,
                      child: Image.asset(
                        'assets/persons/person_raising_hand.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  //marker on driver location
                  if (_hasExistingRequest &&
                      _rideRequestProvider.currentRideRequest!.driver != null)
                    Marker(
                      point: GeolocatorHelper.locationToLatLng(
                        _rideRequestProvider
                            .currentRideRequest!
                            .driver!
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
              if (_rideRequestProvider.currentRideRequest != null)
                PolygonLayer(
                  polygons: [
                    if (Provider.of<PassengerLocationProvider>(
                          context,
                        ).currentLocation !=
                        null)
                      Polygon(
                        points: OSRMService().squareAround(
                          GeolocatorHelper.locationToLatLng(
                            _rideRequestProvider
                                .currentRideRequest!
                                .pickupLocation,
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
                onTap:
                    () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const SearchBottomSheet(),
                    ),
                child: const SearchBarWidget(),
              ),
            ),
          // Confirm Destination Button
          if (_destination != null && !_confirmed! && !_hasExistingRequest)
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
                        (_) => SuggestedPriceModal(
                          distance: _distance,
                          initialTransport: TransportConstants.transports.first,

                          onConfirm: (
                            price,
                            transportType,
                            paymentMethod,
                          ) async {
                            final message = await _rideRequestProvider
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
                                  content: Text(message),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                            setState(() {
                              _confirmed = true;
                            });
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
                  setState(() {
                    _destination = null;
                    _routePolyline.clear();
                    _distance = 0.0;
                    _confirmed = false;
                  });
                },
                child: const Icon(Icons.clear, color: Colors.red),
              ),
            ),
          if (_hasExistingRequest)
            RideRequestCard(
              status: _rideRequestProvider.currentRideRequest!.status!,
              price: 45.00,
              distanceKm: _distance,
              transportType:
                  _rideRequestProvider.currentRideRequest!.transportType!.name,
              driverName:
                  _rideRequestProvider.currentRideRequest!.status! == 'accepted'
                      ? '${_rideRequestProvider.currentRideRequest!.driver!.user!.name} (${_distanceFromDriverToPickup.toStringAsFixed(2)}km)'
                      : null, // or 'Ahmed El Mansouri'
              onCancel: () async {
                // Add your cancel logic here
                final confirmed = await showCancelTripDialog(context, false);

                if (confirmed == null) return;
              },
            ),
        ],
      ),
    );
  }
}
