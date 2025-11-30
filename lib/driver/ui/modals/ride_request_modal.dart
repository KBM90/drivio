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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    builder: (context) {
      return _RideRequestModalContent(
        rideRequest: rideRequest,
        rideRequestProvider: rideRequestProvider,
        driver: driver,
      );
    },
  );
}

class _RideRequestModalContent extends StatefulWidget {
  final RideRequest rideRequest;
  final RideRequestsProvider rideRequestProvider;
  final Driver driver;

  const _RideRequestModalContent({
    required this.rideRequest,
    required this.rideRequestProvider,
    required this.driver,
  });

  @override
  State<_RideRequestModalContent> createState() =>
      _RideRequestModalContentState();
}

class _RideRequestModalContentState extends State<_RideRequestModalContent> {
  bool _isLoading = true;
  String _rating = "N/A";
  String _pickupLocationName = "Unknown Location";
  String _destinationLocationName = "Unknown Location";

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        RatingService.getRating(widget.rideRequest.passenger.userId),
        OSRMService().getPlaceName(
          widget.rideRequest.pickupLocation.latitude ?? 0.0,
          widget.rideRequest.pickupLocation.longitude ?? 0.0,
        ),
        OSRMService().getPlaceName(
          widget.rideRequest.destinationLocation.latitude ?? 0.0,
          widget.rideRequest.destinationLocation.longitude ?? 0.0,
        ),
      ]);

      if (mounted) {
        setState(() {
          // Handle rating
          final ratingData = results[0] as Map<String, dynamic>?;
          if (ratingData != null && ratingData['averageRating'] != null) {
            final avgRating = ratingData['averageRating'] as double;
            _rating = avgRating.toStringAsFixed(1);
          }

          // Handle pickup location
          _pickupLocationName = results[1] as String? ?? "Unknown Location";

          // Handle destination location
          _destinationLocationName =
              results[2] as String? ?? "Unknown Location";

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching ride request data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Stack(
        children: [
          Column(
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
                        widget.rideRequest.transportType?.name ?? "Ride",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "\$${widget.rideRequest.price?.toStringAsFixed(2) ?? "0.00"}",
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
                      Text(_rating, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PassengerProfileScreen(
                                    passengerId:
                                        widget.rideRequest.passenger.userId,
                                  ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              widget.rideRequest.passenger.profileImage != null
                                  ? NetworkImage(
                                    widget.rideRequest.passenger.profileImage!,
                                  )
                                  : null,
                          child:
                              widget.rideRequest.passenger.profileImage == null
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
                    child: Text(
                      _pickupLocationName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    "${widget.rideRequest.estimatedTimeMin} mins (${widget.rideRequest.distanceKm} km)",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.flag, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _destinationLocationName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    "${widget.rideRequest.estimatedTimeMin} mins (${widget.rideRequest.distanceKm} km)",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                  await widget.rideRequestProvider.acceptRideRequest(
                    widget.rideRequest.id,
                    widget.driver.id!,
                    widget.rideRequest.destinationLocation.latitude ?? 0.0,
                    widget.rideRequest.destinationLocation.longitude ?? 0.0,
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
          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.8),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
