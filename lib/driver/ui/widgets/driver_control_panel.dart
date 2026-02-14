import 'dart:async';

import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/widgets/distance_progress_widget.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/services/change_status.dart';
import 'package:drivio_app/driver/services/notifications_services.dart';
import 'package:drivio_app/driver/ui/modals/trip_guide_modal.dart';
import 'package:drivio_app/driver/ui/screens/preferences_page.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:drivio_app/driver/ui/screens/report_map.dart';
import 'package:drivio_app/driver/ui/screens/user_map_reports_screen.dart';
import 'package:drivio_app/driver/ui/screens/ride_recording_screen.dart';
import 'package:drivio_app/driver/ui/screens/location_sharing_screen.dart';
import 'package:drivio_app/driver/ui/screens/crash_report_screen.dart';
import 'package:drivio_app/driver/providers/crash_report_provider.dart';
import 'package:drivio_app/driver/providers/location_sharing_provider.dart';
import 'package:drivio_app/driver/providers/ride_recording_provider.dart';

class DriverControlPanel extends StatefulWidget {
  const DriverControlPanel({super.key});

  @override
  State<DriverControlPanel> createState() => _DriverControlPanelState();
}

class _DriverControlPanelState extends State<DriverControlPanel> {
  Timer? _countdownTimer;
  int _countdownSeconds = 120;
  double distance = 0;
  final ChangeStatus _changeStatus = ChangeStatus();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startCountdown() async {
    _countdownSeconds = 120;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _countdownTimer = null;
      }
    });
  }

  @override
  void didUpdateWidget(covariant DriverControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (distance <= 50 && _countdownTimer == null && distance != 0) {
      _startCountdown();
    } else if (distance > 50) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  Future<void> _sendArrivalNotification(int userId) async {
    try {
      await NotificationsServices().createNotification(
        userId: userId,
        type: "driver_arrived",
        title: "Rider Notified",
        message: "The driver is near you",
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(DriverStatus currentStatus) async {
    try {
      if (currentStatus == DriverStatus.inactive) {
        await _changeStatus.goOnline();
      } else {
        await _changeStatus.goOffline();
      }
      if (mounted) {
        Provider.of<DriverProvider>(context, listen: false).getDriver(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error changing status: $e')));
      }
    }
  }

  Future<void> _refreshRideRequests() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing...'),
        duration: Duration(milliseconds: 500),
      ),
    );

    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final driver = driverProvider.currentDriver;
    if (driver != null && driver.location != null) {
      await Provider.of<RideRequestsProvider>(
        context,
        listen: false,
      ).getNearByRideRequests(
        LatLng(driver.location!.latitude!, driver.location!.longitude!),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  void _showSafetyToolkit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.videocam),
                    title: const Text("Record My Ride"),
                    subtitle: const Text(
                      "Record your trips with your phone or dashcam",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChangeNotifierProvider(
                                  create: (_) => RideRecordingProvider(),
                                  child: const RideRecordingScreen(),
                                ),
                          ),
                        );
                      },
                      child: const Text("Set up"),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_location),
                    title: const Text("Follow My Ride"),
                    subtitle: const Text(
                      "Share location and trip status with family and friends",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChangeNotifierProvider(
                                  create: (_) => LocationSharingProvider(),
                                  child: const LocationSharingScreen(),
                                ),
                          ),
                        );
                      },
                      child: const Text("Send"),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.report, color: Colors.red),
                    title: const Text("Report a crash"),
                    subtitle: const Text(
                      "Report an accident with photos and details",
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChangeNotifierProvider(
                                  create: (_) => CrashReportProvider(),
                                  child: const CrashReportScreen(),
                                ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Report"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showReportToolkit(BuildContext context) {
    final driver =
        Provider.of<DriverProvider>(context, listen: false).currentDriver;
    if (driver == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report a map issue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.grey),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReportOption(
                    context,
                    icon: Icons.traffic,
                    label: 'Traffic',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportMap(
                                reportType: 'Traffic',
                                driver: driver,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildReportOption(
                    context,
                    icon: Icons.car_crash,
                    label: 'Accident',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportMap(
                                reportType: 'Accident',
                                driver: driver,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildReportOption(
                    context,
                    icon: Icons.block,
                    label: 'Closure',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportMap(
                                reportType: 'Closure',
                                driver: driver,
                              ),
                        ),
                      );
                    },
                  ),
                  _buildReportOption(
                    context,
                    icon: Icons.emergency_recording,
                    label: 'Speed Radar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ReportMap(
                                reportType: 'Radar',
                                driver: driver,
                              ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildReportOptionRow(
                context,
                icon: Icons.directions_off,
                label: 'Wrong directions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ReportMap(
                            reportType: 'Wrong Directions',
                            driver: driver,
                          ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (context) {
                      return SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: const UserReportsScreen(reports: []),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.report, color: Colors.black),
                label: const Text(
                  'My reports',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(
              icon,
              size: 30,
              color: label == 'Closure' ? Colors.red : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildReportOptionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(icon, size: 30, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final locationProvider = Provider.of<DriverLocationProvider>(context);
    final rideRequestProvider = Provider.of<RideRequestsProvider>(context);

    final currentDriver = driverProvider.currentDriver;
    final isOffline = currentDriver?.status == DriverStatus.inactive;
    final isOnTrip = currentDriver?.status == DriverStatus.onTrip;

    return DraggableScrollableSheet(
      initialChildSize: isOffline ? 0.2 : 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                spreadRadius: 2,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    if (isOffline) ...[
                      // OFFLINE STATE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.tune,
                              color: Colors.blueAccent,
                            ),
                            tooltip: "Trip Preferences",
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const PreferencesScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Go online to start receiving ride requests.",
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => _toggleStatus(DriverStatus.inactive),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            "GO ONLINE",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ] else if (isOnTrip &&
                        rideRequestProvider.currentRideRequest != null) ...[
                      // ON TRIP STATE
                      _buildTripView(
                        context,
                        driverProvider,
                        locationProvider,
                        rideRequestProvider,
                      ),
                    ] else ...[
                      // ONLINE STATE (Searching)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Finding Trips...",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.blueAccent,
                            ),
                            onPressed: _refreshRideRequests,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        backgroundColor: Colors.blue[50],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildOnlineDashboard(),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.flag_outlined,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          "Report Map Issue",
                          style: TextStyle(color: Colors.orange),
                        ),
                        onPressed: () => _showReportToolkit(context),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleStatus(DriverStatus.active),
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "GO OFFLINE",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTripView(
    BuildContext context,
    DriverProvider driverProvider,
    DriverLocationProvider locationProvider,
    RideRequestsProvider rideRequestProvider,
  ) {
    if (locationProvider.currentLocation == null) return const SizedBox();

    return StreamBuilder<Map<String, dynamic>>(
      stream: Stream.periodic(
        const Duration(seconds: 10),
        (_) => OSRMService().getTimeAndDistanceToPickup(
          locationProvider.currentLocation!,
          LatLng(
            rideRequestProvider.currentRideRequest!.pickupLocation.latitude!,
            rideRequestProvider.currentRideRequest!.pickupLocation.longitude!,
          ),
        ),
      ).asyncMap((future) => future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        distance = snapshot.data!['distance'];
        if (distance <= 50) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _sendArrivalNotification(
              rideRequestProvider.currentRideRequest!.passenger.userId,
            );
          });
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${snapshot.data!['duration']?.toStringAsFixed(0)} min",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text(
                      "to pickup",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${snapshot.data!['distance'].toStringAsFixed(1)} km",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "distance",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            DistanceProgressWidget(
              driverLocation: locationProvider.currentLocation!,
              pickupLocation:
                  rideRequestProvider.currentRideRequest!.pickupLocation,
            ),
            const SizedBox(height: 15),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                rideRequestProvider.currentRideRequest!.passenger.name,
              ),
              subtitle: const Text("Passenger"),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TripGuideModal(
                            driver: driverProvider.currentDriver!,
                            rideRequest:
                                rideRequestProvider.currentRideRequest!,
                          ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.security),
                  label: const Text("Safety"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showSafetyToolkit(context),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text("Report"),
                  onPressed: () => _showReportToolkit(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnlineDashboard() {
    return Column(
      children: [
        _buildDashboardItem(
          Icons.trending_up,
          "High Demand Area",
          "Surge 1.2x",
          Colors.purple,
        ),
        const SizedBox(height: 10),
        _buildDashboardItem(
          Icons.attach_money,
          "Earnings Today",
          "\$0.00",
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildDashboardItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
