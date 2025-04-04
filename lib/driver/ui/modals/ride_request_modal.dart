import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/driver/models/ride_request.dart';
import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<bool?> showRideRequestModal(
  BuildContext context,
  RideRequest rideRequest,
) async {
  return showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "UberX Exclusive",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "\$${rideRequest.price!.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      "4.85",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<String>(
                    future: OSRMService().getPlaceName(
                      rideRequest.pickupLocation.latitude,
                      rideRequest.pickupLocation.longitude,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text(
                          "Loading...",
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ); // Show loading text while fetching
                      } else if (snapshot.hasError) {
                        return const Text(
                          "Unknown Location",
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ); // Show error message if something goes wrong
                      } else {
                        return Text(
                          snapshot.data ?? "Unknown Location",
                          style: const TextStyle(fontSize: 12),
                        ); // Show the fetched place name
                      }
                    },
                  ),
                ),
                Text(
                  "${rideRequest.estimatedTimeMin} mins (${rideRequest.distanceKm} km)",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.flag, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<String>(
                    future: OSRMService().getPlaceName(
                      rideRequest.destinationLocation.latitude,
                      rideRequest.destinationLocation.longitude,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text(
                          "Loading...",
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ); // Show loading text while fetching
                      } else if (snapshot.hasError) {
                        return const Text(
                          "Unknown Location",
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ); // Show error message if something goes wrong
                      } else {
                        return Text(
                          snapshot.data ?? "Unknown Location",
                          style: const TextStyle(fontSize: 12),
                        ); // Show the fetched place name
                      }
                    },
                  ),
                ),
                Text(
                  "${rideRequest.estimatedTimeMin} mins (${rideRequest.distanceKm} km)",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () async {
                await DriverService.accesptRideRequest(
                  rideRequest.id,
                  rideRequest.destinationLocation.latitude,
                  rideRequest.destinationLocation.longitude,
                );
                if (!context.mounted) return;
                Provider.of<DriverStatusProvider>(
                  context,
                  listen: false,
                ).toggleStatus('on_trip');

                Navigator.pop(
                  context,
                  true,
                ); // Return true to the .then() handler
              },
              child: const Text(
                "Accept",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    },
  );
}
