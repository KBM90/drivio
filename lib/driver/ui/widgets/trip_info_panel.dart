import 'dart:async';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/helpers/snack_bar_helper.dart';
import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/common/screens/chat_screen.dart';
import 'package:drivio_app/common/widgets/cancel_trip_dialog.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/services/ride_request_services.dart';
import 'package:drivio_app/driver/ui/screens/passenger_profile.dart';
import 'package:drivio_app/driver/ui/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripInfoPanel extends StatefulWidget {
  final RideRequest rideRequest;

  const TripInfoPanel({super.key, required this.rideRequest});

  @override
  State<TripInfoPanel> createState() => _TripInfoPanelState();
}

class _TripInfoPanelState extends State<TripInfoPanel> {
  final OSRMService _osrmService = OSRMService();
  String _pickupAddress = "Loading...";
  String _dropoffAddress = "Loading...";
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.rideRequest.status ?? '';
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      // Fetch pickup address
      if (widget.rideRequest.pickupLocation.latitude != null &&
          widget.rideRequest.pickupLocation.longitude != null) {
        final pickupAddr = await _osrmService.getPlaceName(
          widget.rideRequest.pickupLocation.latitude,
          widget.rideRequest.pickupLocation.longitude,
        );
        if (mounted) {
          setState(() {
            _pickupAddress = pickupAddr;
          });
        }
      }

      // Fetch dropoff address
      if (widget.rideRequest.destinationLocation.latitude != null &&
          widget.rideRequest.destinationLocation.longitude != null) {
        final dropoffAddr = await _osrmService.getPlaceName(
          widget.rideRequest.destinationLocation.latitude,
          widget.rideRequest.destinationLocation.longitude,
        );
        if (mounted) {
          setState(() {
            _dropoffAddress = dropoffAddr;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
      if (mounted) {
        setState(() {
          _pickupAddress = "Address unavailable";
          _dropoffAddress = "Address unavailable";
        });
      }
    }
  }

  // State for arrival cooldown
  int _arrivedCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startArrivedCooldown() {
    setState(() {
      _arrivedCooldown = 4; // 4 seconds cooldown
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_arrivedCooldown > 0) {
        if (mounted) {
          setState(() {
            _arrivedCooldown--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final passenger = widget.rideRequest.passenger;

    // Listen to real-time updates for this ride request
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('ride_requests')
          .stream(primaryKey: ['id'])
          .eq('id', widget.rideRequest.id),
      builder: (context, snapshot) {
        // Update current status from stream
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final rideData = snapshot.data!.first;
          _currentStatus = rideData['status'] as String;
        }

        return _buildPanel(context, driverProvider, passenger);
      },
    );
  }

  Widget _buildPanel(
    BuildContext context,
    DriverProvider driverProvider,
    dynamic passenger,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35, // Start at 35% of screen height
      minChildSize: 0.2, // Minimum 20% when collapsed
      maxChildSize: 0.75, // Maximum 75% when expanded
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Passenger Info
              Row(
                children: [
                  GestureDetector(
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          passenger.profileImage != null
                              ? NetworkImage(passenger.profileImage!)
                              : null,
                      child:
                          passenger.profileImage == null
                              ? Icon(Icons.person, size: 30, color: Colors.grey)
                              : null,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PassengerProfileScreen(
                                passengerId: passenger.userId,
                              ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${passenger.firstName} ${passenger.lastName}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              passenger.rating?.toStringAsFixed(1) ?? "New",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  if (passenger.phoneNumber != null)
                    IconButton(
                      onPressed: () async {
                        final Uri launchUri = Uri(
                          scheme: 'tel',
                          path: passenger.phoneNumber!,
                        );
                        if (await canLaunchUrl(launchUri)) {
                          await launchUrl(launchUri);
                        }
                      },
                      icon: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.phone, color: Colors.white, size: 20),
                      ),
                    ),
                  // Message Button
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatScreen(
                                otherUserId: passenger.userId,
                                currentUserId:
                                    driverProvider.currentDriver!.userId,
                                otherUserName: passenger.name,
                                currentUserName:
                                    driverProvider.currentDriver!.user?.name ??
                                    "Driver",
                                currentUserRole:
                                    driverProvider.currentDriver!.user?.role ??
                                    "driver",
                              ),
                        ),
                      );
                    },
                    icon: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.message, color: Colors.white, size: 20),
                    ),
                  ),
                  // Profile Button
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              // Trip Details
              _buildLocationRow(
                Icons.my_location,
                Colors.green,
                "Pickup",
                _pickupAddress,
              ),
              const SizedBox(height: 15),
              _buildLocationRow(
                Icons.location_on,
                Colors.red,
                "Dropoff",
                _dropoffAddress,
              ),
              const SizedBox(height: 25),

              // Actions
              if (_currentStatus == 'accepted' || _currentStatus == 'arrived')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _arrivedCooldown > 0
                                ? null // Disable button during cooldown
                                : () async {
                                  try {
                                    await RideRequestService.driverArrived(
                                      widget.rideRequest.id,
                                    );

                                    // Start cooldown immediately
                                    _startArrivedCooldown();

                                    if (!context.mounted) return;
                                    showSnackBar(
                                      context,
                                      "Passenger notified that you have arrived",
                                      backgroundColor: Colors.green,
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    showSnackBar(context, e.toString());
                                  }
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          disabledBackgroundColor: Colors.orange.withOpacity(
                            0.5,
                          ),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _arrivedCooldown > 0
                              ? "Notify Passenger ($_arrivedCooldown s)"
                              : _currentStatus == 'arrived'
                              ? "Notify Passenger Again"
                              : "I've Arrived",
                        ),
                      ),
                    ),
                  ],
                ),

              if (_currentStatus == 'arrived')
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Open QR Scanner
                            final scannedCode = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QRScannerScreen(),
                              ),
                            );

                            if (scannedCode != null && context.mounted) {
                              try {
                                await RideRequestService.startTrip(
                                  widget.rideRequest.id,
                                  scannedCode,
                                );
                                if (!context.mounted) return;
                                showSnackBar(
                                  context,
                                  "Trip started successfully!",
                                  backgroundColor: Colors.green,
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                showSnackBar(context, e.toString());
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Start Trip (Scan QR)"),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_currentStatus == 'in_progress')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement complete trip logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Complete Trip"),
                      ),
                    ),
                  ],
                ),

              if (_currentStatus == 'accepted' ||
                  _currentStatus == 'arrived' ||
                  _currentStatus == 'in_progress')
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final selectedReason = await showCancelTripDialog(
                              context,
                              true,
                            );

                            if (selectedReason == null) return;

                            try {
                              await RideRequestService.cancelTrip(
                                selectedReason,
                              );
                              await driverProvider.toggleStatus('inactive');
                              if (!context.mounted) return;

                              showSnackBar(
                                context,
                                driverProvider.statusMessage!,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              showSnackBar(context, e.toString());
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Cancel Trip"),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    Color color,
    String label,
    String address,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
