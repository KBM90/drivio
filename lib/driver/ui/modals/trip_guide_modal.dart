// lib/widgets/trip_guide_modal.dart
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TripGuideModal extends StatelessWidget {
  const TripGuideModal({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    final rideRequestProvider = Provider.of<RideRequestsProvider>(
      context,
      listen: false,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8, // Prevent overflow
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button and menu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Trip Guide",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      // Handle menu action
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Trip Steps
              _buildTripStep(
                title:
                    "Pickup · ${rideRequestProvider.currentRideRequest!.transportType!.name}",
                subtitle:
                    "Passenger : ${rideRequestProvider.currentRideRequest!.passenger.name}",
                isPickup: true,
              ),
              const SizedBox(height: 16),
              _buildTripStep(
                title:
                    "Dropoff ·${rideRequestProvider.currentRideRequest!.transportType!.name}",
                subtitle:
                    "Passenger : ${rideRequestProvider.currentRideRequest!.passenger.name}",
                isPickup: false,
              ),

              // Dynamic spacer that ensures footer stays at bottom
              Expanded(
                child: SizedBox(
                  height: constraints.maxHeight / 3, // Responsive spacing
                ),
              ),
              // Waybill button
              TextButton(
                onPressed: () {
                  // Handle waybill action
                },
                child: Center(
                  child: const Text(
                    "WAYBILL",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 16),

              // Footer with buttons
              if (driverProvider.currentDriver?.acceptNewRequest == 1)
                _buildFooter(Colors.red, "Stop New Requests", context),
              if (driverProvider.currentDriver?.acceptNewRequest == 0)
                _buildFooter(Colors.green, "Accept New Requests", context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooter(Color color, String text, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Circular Hand Button
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color,
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.pan_tool, color: Colors.white, size: 30),
              onPressed: () async {
                // Handle stop ride requests action
                if (Provider.of<DriverProvider>(
                      context,
                      listen: false,
                    ).currentDriver?.acceptNewRequest ==
                    1) {
                  await Provider.of<DriverProvider>(
                    context,
                    listen: false,
                  ).stopNewRequsts();
                } else {
                  await Provider.of<DriverProvider>(
                    context,
                    listen: false,
                  ).acceptNewRequests();
                }
              },
            ),
          ),
          SizedBox(height: 10),
          // Stop New Requests button
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStep({
    required String title,
    required String subtitle,
    required bool isPickup,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: CircleAvatar(
            backgroundColor: isPickup ? Colors.green : Colors.grey[200],
            child: Icon(
              Icons.person,
              color: isPickup ? Colors.white : Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // Handle more options action
          },
        ),
      ],
    );
  }
}
