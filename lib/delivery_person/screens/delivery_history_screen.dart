import 'package:drivio_app/common/models/delivery_request.dart';
import 'package:drivio_app/delivery_person/screens/delivery_details_screen.dart';
import 'package:drivio_app/delivery_person/services/delivery_person_service.dart';
import 'package:flutter/material.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: const TabBar(
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _DeliveryList(
                  statuses: const [
                    'accepted',
                    'picking_up',
                    'picked_up',
                    'delivering',
                    'price_negotiation',
                  ],
                  statusColor: Colors.orange,
                  emptyMessage: 'No active deliveries',
                ),
                _DeliveryList(
                  statuses: const ['completed'],
                  statusColor: Colors.green,
                  emptyMessage: 'No completed deliveries',
                ),
                _DeliveryList(
                  statuses: const ['cancelled'],
                  statusColor: Colors.red,
                  emptyMessage: 'No cancelled deliveries',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryList extends StatefulWidget {
  final List<String> statuses;
  final Color statusColor;
  final String emptyMessage;

  const _DeliveryList({
    required this.statuses,
    required this.statusColor,
    required this.emptyMessage,
  });

  @override
  State<_DeliveryList> createState() => _DeliveryListState();
}

class _DeliveryListState extends State<_DeliveryList> {
  late Future<List<DeliveryRequest>> _future;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _future = DeliveryPersonService.getDeliveryHistory(
      statuses: widget.statuses,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _fetchData();
        });
        await _future;
      },
      child: FutureBuilder<List<DeliveryRequest>>(
        future: _future,
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
                    onPressed: () {
                      setState(() {
                        _fetchData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final deliveries = snapshot.data ?? [];

          if (deliveries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    widget.emptyMessage,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: deliveries.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                DeliveryDetailsScreen(deliveryId: delivery.id),
                      ),
                    );
                    // Refresh list when returning
                    if (mounted) {
                      setState(() {
                        _fetchData();
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: widget.statusColor.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                _getStatusIcon(delivery.status),
                                color: widget.statusColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Delivery #${delivery.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(delivery.updatedAt!),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(
                                _getStatusText(delivery.status),
                                style: TextStyle(
                                  color: widget.statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: widget.statusColor.withOpacity(
                                0.1,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(
                              Icons.category,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              delivery.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${(delivery.price ?? 0.0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.assignment_turned_in;
      case 'picking_up':
        return Icons.directions_walk;
      case 'picked_up':
        return Icons.shopping_bag;
      case 'delivering':
        return Icons.local_shipping;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'price_negotiation':
        return 'Negotiation';
      case 'picking_up':
        return 'Picking Up';
      case 'picked_up':
        return 'Picked Up';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
