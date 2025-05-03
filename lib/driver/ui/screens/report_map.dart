import 'package:drivio_app/common/constants/map_constants.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/providers/map_reports_provider.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/services/map_report_services.dart';
import 'package:drivio_app/driver/ui/screens/map_view.dart';
import 'package:drivio_app/driver/utils/map_utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ReportMap extends StatefulWidget {
  final String reportType;

  const ReportMap({super.key, required this.reportType});

  @override
  State<ReportMap> createState() => _ReportMapState();
}

class _ReportMapState extends State<ReportMap> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final MapController _mapController = MapController();
  List<LatLng> _routePoints = []; // Points for the drawn route
  LatLng? _selectedPoint; // Single point for marker
  bool _isDrawingRoute = false; // Toggle between point and route mode
  String? _description;
  bool _isMapReady = false;
  late DriverProvider driverProvider;

  @override
  void initState() {
    super.initState();
    driverProvider = Provider.of<DriverProvider>(context, listen: false);
    setState(() {
      _isDrawingRoute = widget.reportType == 'Traffic';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure the map is initialized after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMapReady) {
        _initializeMap();
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      if (driverProvider.currentDriver?.location != null) {
        LatLng driverLocation = LatLng(
          driverProvider.currentDriver!.location!.latitude!,
          driverProvider.currentDriver!.location!.longitude!,
        );

        // Move the map to the driver's location
        _mapController.move(driverLocation, 17.0);
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
    } finally {}
  }

  // Handle map tap to either place a marker or add a point to the route
  void _handleMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      if (_isDrawingRoute) {
        // Route drawing mode: Add the tapped point to the route
        _routePoints.add(latLng);
        _selectedPoint = null; // Clear the marker if in route mode
      } else {
        // Point selection mode: Place a marker at the tapped location
        _selectedPoint = latLng;
        _routePoints = []; // Clear the route if in point mode
      }
    });
  }

  // Clear the current selection (marker or route)
  void _clearSelection() {
    setState(() {
      _selectedPoint = null;
      _routePoints = [];
    });
  }

  // Submit the selected point or route (placeholder for reporting logic)
  Future<bool> _submitReport() async {
    if (_selectedPoint != null) {
      return await MapReportService.submitReport(
        reportType: widget.reportType,
        point: _selectedPoint,
        description: _description,
      );
    } else if (_routePoints.isNotEmpty) {
      return await MapReportService.submitReport(
        reportType: widget.reportType,
        path: _routePoints,
      );
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsProvider = Provider.of<MapReportsProvider>(context);
    final reports = reportsProvider.reports;
    final driverProvider = Provider.of<DriverProvider>(context);

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Reports Map')),
        body: Stack(
          children: [
            // Map
            SizedBox.expand(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      driverProvider.currentDriver?.location != null
                          ? LatLng(
                            driverProvider.currentDriver!.location!.latitude!,
                            driverProvider.currentDriver!.location!.longitude!,
                          )
                          : const LatLng(37.7749, -122.4194), // San Francisco
                  initialZoom: 15.0,
                  onTap: _handleMapTap,
                  onMapReady: () async {
                    setState(() => _isMapReady = true);
                    await _initializeMap();
                  }, // Handle tap events
                ),
                children: [
                  // Tile Layer (OpenStreetMap)
                  TileLayer(urlTemplate: MapConstants.tileLayerUrl),

                  // Add this new MarkerLayer for reports
                  MarkerLayer(
                    markers: MapUtilities().putMarkers(
                      reports
                          .where(
                            (r) =>
                                r.pointLocation != null &&
                                r.routePoints == null,
                          )
                          .toList(),
                    ),
                  ),
                  PolylineLayer(
                    polylines: MapUtilities().drawPolylines(
                      reports.where((r) => r.routePoints != null).toList(),
                    ),
                  ),
                  // Marker Layer for selected point
                  MarkerLayer(
                    markers:
                        _selectedPoint != null
                            ? [
                              Marker(
                                point: _selectedPoint!,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ]
                            : [],
                  ),
                  // Polyline Layer for drawn route
                  PolylineLayer(
                    polylines: [
                      if (_routePoints.isNotEmpty)
                        Polyline(
                          points: _routePoints,
                          color: Colors.blue,
                          strokeWidth: 4.0,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // UI Controls (Top Center)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.02,
              left: 0,
              right: 0,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.reportType != 'Traffic')
                      // Toggle Mode Button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isDrawingRoute = !_isDrawingRoute;
                            _clearSelection(); // Clear selection when switching modes
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          _isDrawingRoute
                              ? 'Switch to Point Mode'
                              : 'Switch to Route Mode',
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Clear Button
                    ElevatedButton(
                      onPressed: _clearSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(255, 10, 6, 237),
                        shape:
                            const CircleBorder(), // This makes it perfectly circular
                        padding: const EdgeInsets.all(
                          2,
                        ), // Adjust padding for size
                        elevation: 1, // Optional shadow
                      ),
                      child: const Icon(
                        Icons.cleaning_services_rounded,
                        size: 20, // Slightly larger icon
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit Button (Bottom Center)
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.02,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // Determine the point to calculate distance to
                    LatLng? targetPoint;
                    if (_selectedPoint != null) {
                      targetPoint = _selectedPoint!;
                    } else if (_routePoints.isNotEmpty) {
                      targetPoint =
                          _routePoints
                              .first; // Use the first point of the route
                    } else {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please select a point or draw a route",
                          ),
                        ),
                      );
                      return;
                    }

                    // Calculate distance
                    final double? distance =
                        await GeolocatorHelper.calculateDistance(targetPoint);
                    // if (!context.mounted) return;
                    if (distance == null) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Unable to get your location. Please ensure location services are enabled.",
                          ),
                        ),
                      );
                      return;
                    }

                    // Check distance
                    const double maxDistanceMeters = 150.0;
                    if (distance >= maxDistanceMeters) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Sorry, this place is out of your range",
                          ),
                        ),
                      );
                      return;
                    }

                    // Submit the report if within range

                    bool reported = await _submitReport();

                    if (reported) {
                      if (_selectedPoint != null) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text('Reported issue at: $_selectedPoint'),
                          ),
                        );
                      } else if (_routePoints.isNotEmpty) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reported issue for route: $_routePoints',
                            ),
                          ),
                        );
                      }
                    } else {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to submit report. Please try again.',
                          ),
                        ),
                      );
                    }
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Submit Report'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
