import 'package:drivio_app/common/models/delivery_request.dart';
import 'package:drivio_app/delivery_person/providers/delivery_person_location_provider.dart';
import 'package:drivio_app/delivery_person/screens/delivery_details_screen.dart';
import 'package:drivio_app/passenger/services/delivery_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryRequestsScreen extends StatefulWidget {
  const DeliveryRequestsScreen({super.key});

  @override
  State<DeliveryRequestsScreen> createState() => _DeliveryRequestsScreenState();
}

class _DeliveryRequestsScreenState extends State<DeliveryRequestsScreen> {
  late Future<List<DeliveryRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      final locationProvider = context.read<DeliveryPersonLocationProvider>();
      final currentLocation = locationProvider.currentLocation;

      if (currentLocation != null) {
        _requestsFuture = DeliveryService.getNearbyDeliveryRequests(
          currentLocation,
        );
      } else {
        // Fallback to old method if location not available
        _requestsFuture = DeliveryService.getAvailableDeliveryRequests();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _loadRequests();
        await _requestsFuture;
      },
      child: FutureBuilder<List<DeliveryRequest>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRequests,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('No available delivery requests found'),
                        SizedBox(height: 8),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final delivery = requests[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                DeliveryDetailsScreen(deliveryId: delivery.id),
                      ),
                    ).then((_) => _loadRequests()); // Refresh on return
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${delivery.category} #${delivery.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    delivery.status == 'accepted'
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                delivery.status == 'accepted'
                                    ? 'Accepted'
                                    : 'New Request',
                                style: TextStyle(
                                  color:
                                      delivery.status == 'accepted'
                                          ? Colors.green
                                          : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (delivery.description != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            delivery.description!,
                            style: TextStyle(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                delivery.pickupNotes ?? 'Pickup Location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.flag_outlined, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                delivery.dropoffNotes ?? 'Dropoff Location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => DeliveryDetailsScreen(
                                          deliveryId: delivery.id,
                                        ),
                                  ),
                                ).then((_) => _loadRequests());
                              },
                              child: const Text('View Details'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
