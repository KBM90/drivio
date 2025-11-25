import 'package:flutter/material.dart';

class RideRequestCard extends StatelessWidget {
  final String transportImagePath;
  final String transportType;
  final double price;
  final String pickupLocation;
  final String destination;
  final double distanceKm;
  final int estimatedTimeMin;

  const RideRequestCard({
    super.key,
    required this.transportImagePath,
    required this.transportType,
    required this.price,
    required this.pickupLocation,
    required this.destination,
    required this.distanceKm,
    required this.estimatedTimeMin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Transport type and price
            Row(
              children: [
                Image.asset(
                  transportImagePath,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.emoji_transportation, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Transport type :$transportType',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Pickup → Destination
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup : $pickupLocation',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Destination :$destination',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Distance and Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car, size: 18),
                    const SizedBox(width: 4),
                    Text('${distanceKm.toStringAsFixed(1)} km'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 4),
                    Text('${estimatedTimeMin.toStringAsFixed(0)} min'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
