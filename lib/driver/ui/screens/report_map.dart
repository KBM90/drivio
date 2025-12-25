import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/providers/map_reports_provider.dart';
import 'package:drivio_app/common/widgets/cached_tile_layer.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/map_report_services.dart';
import 'package:drivio_app/driver/utils/map_utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class ReportMap extends StatelessWidget {
  final String reportType;
  final Driver driver;
  const ReportMap({super.key, required this.reportType, required this.driver});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MapReportsProvider()),
      ],
      child: ReportMapScreen(reportType: reportType, driver: driver),
    );
  }
}

class ReportMapScreen extends StatefulWidget {
  final String reportType;
  final Driver driver;

  const ReportMapScreen({
    super.key,
    required this.reportType,
    required this.driver,
  });

  @override
  State<ReportMapScreen> createState() => _ReportMapScreenState();
}

class _ReportMapScreenState extends State<ReportMapScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final MapController _mapController = MapController();
  List<LatLng> _routePoints = []; // Points for the drawn route
  LatLng? _selectedPoint; // Single point for marker
  bool _isDrawingRoute = false; // Toggle between point and route mode
  String? _description;

  @override
  void initState() {
    super.initState();

    // Initialize drawing mode based on report type (no setState needed in initState)
    _isDrawingRoute = widget.reportType == 'Traffic';
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      if (widget.driver.location != null &&
          widget.driver.location!.latitude != null &&
          widget.driver.location!.longitude != null) {
        LatLng driverLocation = LatLng(
          widget.driver.location!.latitude!,
          widget.driver.location!.longitude!,
        );

        // Small delay to ensure map is ready
        await Future.delayed(const Duration(milliseconds: 100));

        // Move the map to the driver's location
        _mapController.move(driverLocation, 17.0);

        // Force a tiny rotation to trigger tile loading
        await Future.delayed(const Duration(milliseconds: 50));
        _mapController.rotate(0.0001);
        await Future.delayed(const Duration(milliseconds: 50));
        _mapController.rotate(0.0);
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
    }
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

  // Submit the selected point or route and refresh reports
  Future<bool> _submitReport(BuildContext context) async {
    if (_selectedPoint != null) {
      final success = await MapReportService.submitReport(
        reportType: widget.reportType,
        point: _selectedPoint,
        description: _description,
      );
      if (success && context.mounted) {
        // Refresh reports after successful submission
        Provider.of<MapReportsProvider>(
          context,
          listen: false,
        ).getReportsWithinRadius();
      }
      return success;
    } else if (_routePoints.isNotEmpty) {
      final success = await MapReportService.submitReport(
        reportType: widget.reportType,
        path: _routePoints,
      );
      if (success && context.mounted) {
        // Refresh reports after successful submission
        Provider.of<MapReportsProvider>(
          context,
          listen: false,
        ).getReportsWithinRadius();
      }
      return success;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(title: const Text('Reports Map')),
        body: Consumer<MapReportsProvider>(
          builder: (context, reportsProvider, child) {
            final reports = reportsProvider.reports;
            final isLoading = reportsProvider.isLoading;
            final errorMessage = reportsProvider.errorMessage;

            return Stack(
              children: [
                // Map
                SizedBox.expand(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          widget.driver.location != null
                              ? LatLng(
                                widget.driver.location!.latitude!,
                                widget.driver.location!.longitude!,
                              )
                              : const LatLng(
                                31.7917, // Rough center of Morocco
                                -7.0926,
                              ),
                      initialZoom: 15.0,
                      onTap: _handleMapTap,
                      onMapReady: _initializeMap,
                    ),
                    children: [
                      // Tile Layer (OpenStreetMap)
                      CachedTileLayer(),

                      // MarkerLayer for existing reports
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
                      // PolylineLayer for existing route reports
                      PolylineLayer(
                        polylines: MapUtilities().drawPolylines(
                          reports.where((r) => r.routePoints != null).toList(),
                        ),
                      ),
                      // Marker Layer for user's selected point
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
                      // Polyline Layer for user's drawn route
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

                // Loading indicator
                if (isLoading)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                // Error message
                if (errorMessage != null && !isLoading)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Material(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                                _clearSelection();
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
                            foregroundColor: const Color.fromARGB(
                              255,
                              10,
                              6,
                              237,
                            ),
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(2),
                            elevation: 1,
                          ),
                          child: const Icon(
                            Icons.cleaning_services_rounded,
                            size: 20,
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
                            await GeolocatorHelper.calculateDistance(
                              targetPoint,
                            );
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
                        bool reported = await _submitReport(context);

                        if (reported) {
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Report submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Clear selection after successful submission
                          _clearSelection();
                        } else {
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to submit report. Please try again.',
                              ),
                              backgroundColor: Colors.red,
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
            );
          },
        ),
      ),
    );
  }
}
