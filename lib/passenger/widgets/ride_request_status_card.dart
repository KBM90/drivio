import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/common/screens/chat_screen.dart';
import 'package:drivio_app/common/services/rating_services.dart';
import 'package:drivio_app/passenger/screens/passenger_map_view.dart';
import 'package:flutter/material.dart';
import 'package:drivio_app/common/models/ride_request.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:drivio_app/passenger/providers/passenger_ride_request_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RideRequestStatusWidget extends StatelessWidget {
  final RideRequest rideRequest;
  double? distance;

  RideRequestStatusWidget({
    super.key,
    required this.rideRequest,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ No StreamBuilder needed - provider already handles real-time updates
    // The rideRequest is updated by PassengerRideRequestProvider
    final currentStatus = rideRequest.status;
    final qrCode = rideRequest.qrCode;
    final qrCodeScanned = rideRequest.qrCodeScanned ?? false;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Header
          _buildStatusHeader(currentStatus!),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ✅ QR Code Section (when driver arrived)
                if (currentStatus == 'arrived' &&
                    qrCode != null &&
                    !qrCodeScanned)
                  _buildQrCodeSection(qrCode),
                // Driver Info or Searching
                if (currentStatus == 'pending' ||
                    currentStatus == 'cancelled_by_driver')
                  _buildSearchingDriver(),

                if (currentStatus == 'accepted')
                  _buildDriverInfo(
                    context,
                    rideRequest.driver?.user?.name ?? 'Driver',
                    rideRequest.driver?.userId ?? 0,
                  ),

                const SizedBox(height: 20),

                // Progress Bar (only for accepted status)
                if (currentStatus == 'accepted')
                  _buildProgressBar(context, rideRequest.driver?.userId ?? 0),

                const SizedBox(height: 20),

                // Trip Details
                _buildTripDetails(),

                const SizedBox(height: 20),

                // Action Buttons
                if (currentStatus == 'accepted' ||
                    currentStatus == 'cancelled_by_driver' ||
                    currentStatus == 'pending')
                  _buildActionButtons(context, currentStatus, rideRequest),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config['colors'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              config['icon'] as IconData,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride Status',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  config['text'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingDriver() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.orange.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade500],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              const Icon(Icons.directions_car, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Finding your driver',
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This usually takes less than a minute',
                  style: TextStyle(color: Colors.amber.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(
    BuildContext context,
    String driverName,
    int driverId,
  ) {
    dynamic driverRating = 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade500, Colors.indigo.shade600],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
              if (rideRequest.status == 'accepted')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder(
                  future: RatingService.getRating(driverId),
                  builder: (context, ratingSnapShot) {
                    if (ratingSnapShot.hasData) {
                      driverRating = ratingSnapShot.data!['averageRating'];
                      print(driverRating);
                    }
                    return Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          driverRating.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• Toyota Corolla',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${distance?.toStringAsFixed(1) ?? "0.0"}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'km away',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, int driverId) {
    // Watch driver location from Supabase
    final stream = Supabase.instance.client
        .from('drivers')
        .stream(primaryKey: ['id'])
        .eq('id', driverId)
        .map((list) => list.isNotEmpty ? list.first : null);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: stream,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle errors
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // Handle missing or empty data
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("No status data available"));
        }

        final data = snapshot.data!;

        // Parse location from GeoJSON
        final coords = GeolocatorHelper.parseGeoJSON(data['location']);
        if (coords == null) {
          return const Center(child: Text("Driver location unavailable"));
        }

        final LatLng currentDriverLocation = LatLng(
          coords['latitude']!,
          coords['longitude']!,
        );
        final LatLng passengerLocation = GeolocatorHelper.locationToLatLng(
          rideRequest.pickupLocation,
        );

        double? lastProgress;

        return FutureBuilder(
          future: OSRMService().getDistance(
            currentDriverLocation,
            passengerLocation,
          ),
          builder: (context, distanceSnapshot) {
            if (distanceSnapshot.hasData) {
              distance = distanceSnapshot.data!;
              lastProgress = _calculateProgress(distance);
            }

            final progressToShow = lastProgress ?? 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: Colors.blue.shade500,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          distance != null && distance! < 10
                              ? 'Driver arrived'
                              : "Driver approaching",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    FutureBuilder(
                      future: OSRMService().getFormattedDuration(
                        currentDriverLocation,
                        passengerLocation,
                      ),
                      builder: (context, durationSnapshot) {
                        return Text(
                          '~${durationSnapshot.data ?? "5 min"}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progressToShow,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade500,
                              Colors.indigo.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    Positioned(
                      left:
                          MediaQuery.of(context).size.width *
                              progressToShow *
                              0.85 -
                          36,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_car,
                          color: Colors.blue.shade600,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Starting point',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'Your location',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTripDetails() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          FutureBuilder(
            future: OSRMService().getPlaceName(
              rideRequest.pickupLocation.latitude,
              rideRequest.pickupLocation.longitude,
            ),
            builder: (context, placeNameSnapshot) {
              String placeName = 'Fetching pickup name ...';
              if (placeNameSnapshot.hasData) {
                placeName = placeNameSnapshot.data!;
              }
              return _buildLocationRow(
                icon: Icons.location_on,
                iconColor: Colors.green,
                backgroundColor: Colors.green.shade50,
                label: 'Pickup',
                address: placeName,
              );
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: OSRMService().getPlaceName(
              rideRequest.destinationLocation.latitude,
              rideRequest.destinationLocation.longitude,
            ),
            builder: (context, placeNameSnapshot) {
              String placeName = 'Fetching destination name ...';
              if (placeNameSnapshot.hasData) {
                placeName = placeNameSnapshot.data!;
              }
              return _buildLocationRow(
                icon: Icons.location_on,
                iconColor: Colors.red,
                backgroundColor: Colors.red.shade50,
                label: 'Destination',
                address: placeName,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    String status,
    RideRequest ride,
  ) {
    if (status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Provider.of<PassengerRideRequestProvider>(
              context,
              listen: false,
            ).cancelRideRequest('cancelled befor accepted');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Cancel Request',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    if (status == 'cancelled_by_driver') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PassengerMapScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 24, 115, 251),
            foregroundColor: const Color.fromARGB(255, 12, 46, 81),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Show map',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Message driver
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatScreen(
                        currentUserId: rideRequest.passenger.userId,
                        otherUserId: rideRequest.driver!.userId,
                        currentUserName: rideRequest.passenger.name,
                        otherUserName: rideRequest.driver!.user!.name,
                        currentUserRole: 'passenger',
                      ),
                ),
              );
            },
            icon: const Icon(Icons.message, size: 18),
            label: const Text('Message'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Call driver
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {
          'colors': [Colors.amber.shade400, Colors.orange.shade500],
          'text': 'Searching for driver...',
          'icon': Icons.search,
        };
      case 'accepted':
        return {
          'colors': [Colors.blue.shade500, Colors.indigo.shade600],
          'text': 'Driver on the way',
          'icon': Icons.navigation,
        };
      case 'arrived':
        return {
          'colors': [Colors.green.shade500, Colors.teal.shade600],
          'text': 'Driver has arrived',
          'icon': Icons.location_on,
        };
      case 'in_progress':
        return {
          'colors': [Colors.purple.shade500, Colors.deepPurple.shade600],
          'text': 'Ride in progress',
          'icon': Icons.directions_car,
        };
      case 'cancelled_by_driver':
        return {
          'colors': [
            const Color.fromARGB(255, 233, 207, 8),
            const Color.fromARGB(255, 104, 83, 13),
          ],
          'text': 'Driver cancelled the trip',
          'icon': Icons.warning,
        };
      default:
        return {
          'colors': [Colors.grey.shade400, Colors.grey.shade600],
          'text': 'Unknown status',
          'icon': Icons.help_outline,
        };
    }
  }

  double _calculateProgress(double? driverDis) {
    // Calculate progress based on driver distance
    // Assuming max distance is 10km, adjust as needed
    if (driverDis == null) return 0.35;

    final maxDistance = 10.0;
    final progress = 1 - (driverDis / maxDistance).clamp(0.0, 1.0);
    return progress.clamp(0.1, 0.95);
  }

  Widget _buildQrCodeSection(String qrCodeValue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Has Arrived!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Show this QR code to your driver',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: QrImageView(
              data: qrCodeValue,
              version: QrVersions.auto,
              size: 180.0,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),

          const SizedBox(height: 16),

          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.green.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Driver will scan to start trip',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
