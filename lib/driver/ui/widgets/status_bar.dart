import 'dart:async';

import 'package:drivio_app/common/helpers/date_time_helpers.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/screens/chat_screen.dart';
import 'package:drivio_app/common/widgets/distance_progress_widget.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/passenger_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/services/notifications_services.dart';
import 'package:drivio_app/driver/ui/modals/trip_guide_modal.dart';
import 'package:drivio_app/driver/ui/screens/passenger_profile.dart';
import 'package:drivio_app/driver/ui/widgets/preferences_button.dart';
import 'package:drivio_app/driver/ui/widgets/recommanded_for_you_button.dart';
import 'package:drivio_app/driver/ui/widgets/rider_notified_countdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  Timer? _countdownTimer;
  int _countdownSeconds = 120;
  double distance = 0;
  // Add this to your initState
  @override
  void initState() {
    super.initState();
    _countdownTimer?.cancel(); // Cancel any existing timer
  }

  // Add this to your dispose
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
  void didUpdateWidget(covariant StatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (distance <= 50 && _countdownTimer == null && distance != 0) {
      _startCountdown();
    } else if (distance > 50) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
    }
  }

  // Elsewhere in your widget class
  Future<void> _sendArrivalNotification(int userdId) async {
    try {
      await NotificationsServices().createNotification(
        userId: userdId,
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

  @override
  Widget build(BuildContext context) {
    // final locationProvider = Provider.of<DriverLocationProvider>(context);
    final rideRequestProvider = Provider.of<RideRequestsProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.1, // Start small
      minChildSize: 0.1, // Minimum height
      maxChildSize: 1, // Maximum height
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 244, 241, 241),
            borderRadius: const BorderRadius.vertical(top: Radius.zero),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ ListView starts AFTER the Red Bar
              Flexible(
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
                  children: [
                    // ✅ Move the Red Bar Here (OUTSIDE ListView)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: 0,
                      ),
                      color: const Color.fromARGB(255, 244, 241, 241),
                      child: Consumer2<DriverProvider, DriverLocationProvider>(
                        builder: (
                          context,
                          driverProvider,
                          locationProvider,
                          child,
                        ) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PreferencesButton(),
                              if (driverProvider.currentDriver?.status ==
                                  DriverStatus.inactive)
                                Text(
                                  "You're offline",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (driverProvider.currentDriver?.status ==
                                  DriverStatus.active)
                                Text(
                                  "You're online",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (driverProvider.currentDriver?.status ==
                                      DriverStatus.onTrip &&
                                  locationProvider.currentLocation != null &&
                                  rideRequestProvider.currentRideRequest !=
                                      null &&
                                  rideRequestProvider.isLoading == false)
                                FutureBuilder<Map<String, dynamic>>(
                                  future: OSRMService()
                                      .getTimeAndDistanceToPickup(
                                        locationProvider.currentLocation!,
                                        LatLng(
                                          rideRequestProvider
                                              .currentRideRequest!
                                              .pickupLocation
                                              .latitude!,
                                          rideRequestProvider
                                              .currentRideRequest!
                                              .pickupLocation
                                              .longitude!,
                                        ),
                                      ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                            ConnectionState.waiting ||
                                        rideRequestProvider
                                                .currentRideRequest ==
                                            null) {
                                      return SizedBox();
                                    } else if (snapshot.hasError) {
                                      return const Center(
                                        child: Text('Error loading route info'),
                                      );
                                    } else {
                                      distance = snapshot.data!['distance'];
                                      if (distance <= 50) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              _sendArrivalNotification(
                                                rideRequestProvider
                                                    .currentRideRequest!
                                                    .passenger
                                                    .userId,
                                              ); // Call a separate async function
                                            });
                                      }

                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(
                                                context,
                                              ).size.width /
                                              2,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 0.0,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (snapshot.data!['distance'] <=
                                                  50) ...{
                                                RiderNotifiedCountdown(
                                                  shouldShow: true,
                                                  passengerName:
                                                      rideRequestProvider
                                                          .currentRideRequest!
                                                          .passenger
                                                          .name,
                                                ),
                                              } else ...{
                                                Row(
                                                  // Your existing distance/time row
                                                  children: [
                                                    Text(
                                                      '${snapshot.data!['duration']?.toStringAsFixed(1)} min',
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.person_4_rounded,
                                                        color: Color.fromARGB(
                                                          255,
                                                          24,
                                                          8,
                                                          248,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    const TripGuideModal(),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    Text(
                                                      '${snapshot.data!['distance'].toStringAsFixed(1)} km',
                                                    ),
                                                  ],
                                                ),
                                              },
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '${snapshot.data!['duration']?.toStringAsFixed(1)} min',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.person_4_rounded,
                                                      color: Color.fromARGB(
                                                        255,
                                                        24,
                                                        8,
                                                        248,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                                  const TripGuideModal(),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  Text(
                                                    '${snapshot.data!['distance'].toStringAsFixed(1)} km',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              // Progress bar
                                              DistanceProgressWidget(
                                                driverLocation:
                                                    locationProvider
                                                        .currentLocation!,
                                                pickupLocation:
                                                    rideRequestProvider
                                                        .currentRideRequest!
                                                        .pickupLocation,
                                              ),

                                              // Pickup info - minimal version like your screenshot
                                              Text(
                                                "Pickup ${rideRequestProvider.currentRideRequest!.passenger.name}",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),

                              RecommandedForYouButton(
                                onPressed: () {
                                  print("Toggle clicked");
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (driverProvider.currentDriver?.status ==
                        DriverStatus.active)
                      ListTile(
                        leading: Icon(Icons.car_repair, color: Colors.blue),
                        title: Text("Get 10-40% off car services"),
                        subtitle: Text("Save on maintenance & repair"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    if (driverProvider.currentDriver?.status ==
                        DriverStatus.active)
                      ListTile(
                        leading: Icon(Icons.local_offer, color: Colors.green),
                        title: Text("Enjoy more benefits with Drivio Pro"),
                        subtitle: Text("Exclusive savings and discounts"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    if (driverProvider.currentDriver?.status ==
                        DriverStatus.inactive)
                      ListTile(
                        leading: Icon(Icons.car_repair, color: Colors.blue),
                        title: Text("Get 10-40% off car services"),
                        subtitle: Text("Save on maintenance & repair"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    if (driverProvider.currentDriver?.status ==
                        DriverStatus.inactive)
                      ListTile(
                        leading: Icon(Icons.local_offer, color: Colors.green),
                        title: Text("Enjoy more benefits with Drivio Pro"),
                        subtitle: Text("Exclusive savings and discounts"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    if (driverProvider.currentDriver?.status ==
                        DriverStatus.onTrip)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.phone),
                            onPressed: () {
                              // Navigate to the ChatScreen when the phone icon is clicked
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatScreen(
                                        passengerId:
                                            rideRequestProvider
                                                .currentRideRequest!
                                                .passenger
                                                .userId,
                                        driverId:
                                            driverProvider
                                                .currentDriver!
                                                .userId,
                                      ),
                                ),
                              );
                            },
                          ),
                          const Text('Melody', style: TextStyle(fontSize: 20)),
                          IconButton(
                            icon: const Icon(Icons.person),
                            onPressed: () async {
                              await Provider.of<PassengerProvider>(
                                context,
                                listen: false,
                              ).getPassenger(
                                rideRequestProvider
                                    .currentRideRequest!
                                    .passenger
                                    .id,
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PassengerProfileScreen(
                                        passengerId:
                                            rideRequestProvider
                                                .currentRideRequest!
                                                .passenger
                                                .userId,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _buildNotifierCountDown(distance) {
    return Column(
      children: [
        Center(child: Text("Rider Notified")),
        Center(
          child: Text(
            formatCountdown(_countdownSeconds),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
