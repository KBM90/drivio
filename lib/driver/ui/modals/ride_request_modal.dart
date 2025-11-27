import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/services/rating_services.dart';
import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/providers/ride_requests_provider.dart';
import 'package:drivio_app/driver/ui/screens/passenger_profile.dart';
import 'package:flutter/material.dart';

Future<bool?> showRideRequestModal(
  BuildContext context,
  RideRequest rideRequest,
  RideRequestsProvider rideRequestProvider,
  Driver driver,
) async {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: false,
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
                    Text(
                      rideRequest.transportType?.name ?? "Ride",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "\$${rideRequest.price?.toStringAsFixed(2) ?? "0.00"}",
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
                    FutureBuilder<Map<String, dynamic>?>(
                      future: RatingService.getRating(rideRequest.passenger.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text(
                            "Loading...",
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ); // Show loading text while fetching
                        } else if (snapshot.hasError) {
                          return const Text(
                            "Error fetching rating",
                            style: TextStyle(fontSize: 14, color: Colors.red),
                          ); // Show error message if something goes wrong
                        } else {
                          if (snapshot.data == null) {
                            return Text(
                              "NaN",
                              style: const TextStyle(fontSize: 12),
                            );
                          } else {
                            return Text(
                              "${snapshot.data!['averageRating']}",
                              style: const TextStyle(fontSize: 12),
                            );
                          } // Show the fetched place name
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PassengerProfileScreen(
                                  passengerId: rideRequest.passenger.userId,
                                ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        backgroundImage:
                            rideRequest.passenger.profileImage != null
                                ? NetworkImage(
                                  rideRequest.passenger.profileImage!,
                                )
                                : null,
                        child:
                            rideRequest.passenger.profileImage == null
                                ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.grey,
                                )
                                : null,
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
                      rideRequest.pickupLocation.latitude ?? 0.0,
                      rideRequest.pickupLocation.longitude ?? 0.0,
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
                      rideRequest.destinationLocation.latitude ?? 0.0,
                      rideRequest.destinationLocation.longitude ?? 0.0,
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
                await rideRequestProvider.acceptRideRequest(
                  rideRequest.id,
                  driver.id!,
                  rideRequest.destinationLocation.latitude ?? 0.0,
                  rideRequest.destinationLocation.longitude ?? 0.0,
                );

                if (!context.mounted) return;
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
