import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/driver/providers/driver_location_provider.dart';
import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/ui/modals/trip_guide_modal.dart';
import 'package:drivio_app/driver/ui/widgets/preferences_button.dart';
import 'package:drivio_app/driver/ui/widgets/recommanded_for_you_button.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  @override
  Widget build(BuildContext context) {
    final driverStatusProvider = Provider.of<DriverStatusProvider>(context);
    final locationProvider = Provider.of<DriverLocationProvider>(context);
    final rideRequestProvider = Provider.of<RideRequestsProvider>(context);

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
                      child: Consumer<DriverStatusProvider>(
                        builder: (context, provider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PreferencesButton(),
                              if (provider.driverStatus == 'inactive')
                                Text(
                                  "You're offline",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (provider.driverStatus == 'active')
                                Text(
                                  "You're online",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (provider.driverStatus == 'on_trip' &&
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
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return const Center(
                                        child: Text('Error loading route info'),
                                      );
                                    } else {
                                      final duration =
                                          snapshot.data!['duration']?.round() ??
                                          0;
                                      final distance =
                                          snapshot.data!['distance']
                                              ?.toStringAsFixed(1) ??
                                          '0.0';

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
                                              // Time and distance row - exactly like your screenshot
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '$duration min',
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
                                                      showModalBottomSheet(
                                                        context: context,
                                                        isScrollControlled:
                                                            true,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        builder:
                                                            (context) =>
                                                                const TripGuideModal(),
                                                      );
                                                    },
                                                  ),
                                                  Text(
                                                    '$distance mi',
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
                                              SizedBox(
                                                width:
                                                    double
                                                        .infinity, // Takes full available width
                                                child: LinearProgressIndicator(
                                                  value: 0.3,
                                                  backgroundColor:
                                                      Colors.grey[200],
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.blue),
                                                ),
                                              ),

                                              // Pickup info - minimal version like your screenshot
                                              Text(
                                                rideRequestProvider
                                                    .currentRideRequest!
                                                    .passenger
                                                    .name,
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
                    if (driverStatusProvider.driverStatus == 'active')
                      ListTile(
                        leading: Icon(Icons.car_repair, color: Colors.blue),
                        title: Text("Get 10-40% off car services"),
                        subtitle: Text("Save on maintenance & repair"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    if (driverStatusProvider.driverStatus == 'active')
                      ListTile(
                        leading: Icon(Icons.local_offer, color: Colors.green),
                        title: Text("Enjoy more benefits with Drivio Pro"),
                        subtitle: Text("Exclusive savings and discounts"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    if (driverStatusProvider.driverStatus == 'inactive')
                      ListTile(
                        leading: Icon(Icons.car_repair, color: Colors.blue),
                        title: Text("Get 10-40% off car services"),
                        subtitle: Text("Save on maintenance & repair"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    if (driverStatusProvider.driverStatus == 'inactive')
                      ListTile(
                        leading: Icon(Icons.local_offer, color: Colors.green),
                        title: Text("Enjoy more benefits with Drivio Pro"),
                        subtitle: Text("Exclusive savings and discounts"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    if (driverStatusProvider.driverStatus == 'on_trip')
                      ListTile(
                        leading: Icon(Icons.car_repair, color: Colors.blue),
                        title: Text("Get 10-40% off car services"),
                        subtitle: Text("Save on maintenance & repair"),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
}
