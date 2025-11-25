import 'package:flutter/material.dart';

class RideRequestCard extends StatelessWidget {
  final String status;
  final double price;
  final double distanceKm;
  final String transportType;
  final String? driverName;
  final VoidCallback onCancel;

  const RideRequestCard({
    super.key,
    required this.status,
    required this.price,
    required this.distanceKm,
    required this.transportType,
    this.driverName,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ride Status: ${status[0].toUpperCase()}${status.substring(1)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Price: \$${price.toStringAsFixed(2)}'),
                  Text('Distance: ${distanceKm.toStringAsFixed(2)} km'),
                  Text('Transport Type: $transportType'),
                  if (driverName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Accepted by: $driverName',
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Ride'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
