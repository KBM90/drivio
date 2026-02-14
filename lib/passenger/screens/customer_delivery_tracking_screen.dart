import 'dart:async';
import 'package:drivio_app/common/models/delivery_request.dart';
import 'package:drivio_app/delivery_person/models/delivery_person.dart';
import 'package:drivio_app/delivery_person/services/delivery_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen for customers to track their delivery in real-time
class CustomerDeliveryTrackingScreen extends StatefulWidget {
  final int deliveryId;

  const CustomerDeliveryTrackingScreen({super.key, required this.deliveryId});

  @override
  State<CustomerDeliveryTrackingScreen> createState() =>
      _CustomerDeliveryTrackingScreenState();
}

class _CustomerDeliveryTrackingScreenState
    extends State<CustomerDeliveryTrackingScreen> {
  DeliveryRequest? _deliveryRequest;
  DeliveryPerson? _deliveryPerson;
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _deliverySubscription;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _loadDeliveryData();
    _listenToUpdates();
  }

  @override
  void dispose() {
    _deliverySubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDeliveryData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final delivery = await DeliveryService.getDeliveryRequestById(
        widget.deliveryId,
      );
      setState(() => _deliveryRequest = delivery);

      // Load delivery person if assigned
      if (delivery.deliveryPersonId != null) {
        final deliveryPerson =
            await DeliveryService.getDeliveryPersonWithLocation(
              delivery.deliveryPersonId!,
            );
        setState(() => _deliveryPerson = deliveryPerson);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _listenToUpdates() {
    // Listen to delivery request updates
    _deliverySubscription = DeliveryService.listenToDeliveryUpdates(
      widget.deliveryId,
    ).listen((delivery) {
      setState(() => _deliveryRequest = delivery);

      // If delivery person just got assigned, load their info
      if (delivery.deliveryPersonId != null && _deliveryPerson == null) {
        _loadDeliveryPersonLocation(delivery.deliveryPersonId!);
      }
    });
  }

  void _loadDeliveryPersonLocation(int deliveryPersonId) {
    _locationSubscription?.cancel();
    _locationSubscription = DeliveryService.listenToDeliveryPersonLocation(
      deliveryPersonId,
    ).listen((deliveryPerson) {
      setState(() => _deliveryPerson = deliveryPerson);
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'price_negotiation':
        return Colors.purple;
      case 'accepted':
        return Colors.blue;
      case 'picking_up':
        return Colors.orange;
      case 'picked_up':
        return Colors.deepPurple;
      case 'delivering':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'price_negotiation':
        return Icons.campaign;
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
      case 'pending':
        return 'Waiting for Delivery Person';
      case 'price_negotiation':
        return 'Price Proposal Received';
      case 'accepted':
        return 'Delivery Person Assigned';
      case 'picking_up':
        return 'Picking Up Your Item';
      case 'picked_up':
        return 'Item Picked Up';
      case 'delivering':
        return 'On the Way to You';
      case 'completed':
        return 'Delivery Completed';
      case 'cancelled':
        return 'Delivery Cancelled';
      default:
        return status;
    }
  }

  Future<void> _callDeliveryPerson() async {
    if (_deliveryPerson?.user?.phone == null) return;

    final uri = Uri.parse('tel:${_deliveryPerson!.user!.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _cancelDelivery() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Delivery?'),
            content: const Text(
              'Are you sure you want to cancel this delivery? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await DeliveryService.cancelDeliveryRequest(widget.deliveryId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Delivery cancelled')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _acceptPrice() async {
    try {
      setState(() => _isLoading = true);
      await DeliveryService.acceptProposedPrice(widget.deliveryId);
      await _loadDeliveryData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Price accepted! Delivery is now confirmed.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Reload data to ensure consistent state even if error occurred
        await _loadDeliveryData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectPrice() async {
    try {
      setState(() => _isLoading = true);
      await DeliveryService.rejectProposedPrice(widget.deliveryId);
      await _loadDeliveryData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Price proposal rejected. Request is pending again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await _loadDeliveryData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Tracking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Tracking')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDeliveryData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_deliveryRequest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Delivery Tracking')),
        body: const Center(child: Text('Delivery not found')),
      );
    }

    final delivery = _deliveryRequest!;
    final status = delivery.status;
    final canCancel =
        status == 'pending' || status == 'accepted' || status == 'picking_up';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Delivery'),
        actions: [
          if (canCancel)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: _cancelDelivery,
              tooltip: 'Cancel Delivery',
            ),
        ],
      ),
      body: Column(
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _getStatusColor(status).withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                      if (delivery.category.isNotEmpty)
                        Text(
                          '${delivery.category} Delivery',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Price Proposal Notification
          if (status == 'price_negotiation' && delivery.proposedPrice != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.purple),
                      const SizedBox(width: 8),
                      const Text(
                        'New Price Proposal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The delivery person has proposed a new price for your delivery:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Original',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '\$${delivery.price?.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey),
                      Column(
                        children: [
                          const Text(
                            'Proposed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          Text(
                            '\$${delivery.proposedPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rejectPrice,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _acceptPrice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Accept \$${delivery.proposedPrice!.toStringAsFixed(0)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Map view (if delivery person assigned and has location)
          if (_deliveryPerson?.currentLocation != null)
            Expanded(
              flex: 2,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    _deliveryPerson!.currentLocation!.latitude!,
                    _deliveryPerson!.currentLocation!.longitude!,
                  ),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.drivio',
                  ),
                  MarkerLayer(
                    markers: [
                      // Delivery person marker
                      Marker(
                        point: LatLng(
                          _deliveryPerson!.currentLocation!.latitude!,
                          _deliveryPerson!.currentLocation!.longitude!,
                        ),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                      // Delivery location marker
                      if (delivery.deliveryLocation != null)
                        Marker(
                          point: LatLng(
                            delivery.deliveryLocation!.latitude!,
                            delivery.deliveryLocation!.longitude!,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

          // Details section
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery person info
                  if (_deliveryPerson != null) ...[
                    const Text(
                      'Delivery Person',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(_deliveryPerson!.user?.name[0] ?? 'D'),
                        ),
                        title: Text(
                          _deliveryPerson!.user?.name ?? 'Delivery Person',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_deliveryPerson!.vehicleType != null)
                              Text('Vehicle: ${_deliveryPerson!.vehicleType}'),
                            Text(
                              'Rating: ${_deliveryPerson!.rating.toStringAsFixed(1)} ⭐',
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: _callDeliveryPerson,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Delivery details
                  const Text(
                    'Delivery Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (delivery.description != null)
                    _buildDetailRow(
                      Icons.description,
                      'Item',
                      delivery.description!,
                    ),
                  if (delivery.pickupNotes != null)
                    _buildDetailRow(
                      Icons.store,
                      'Pickup Notes',
                      delivery.pickupNotes!,
                    ),
                  if (delivery.dropoffNotes != null)
                    _buildDetailRow(
                      Icons.home,
                      'Dropoff Notes',
                      delivery.dropoffNotes!,
                    ),
                  if (delivery.price != null)
                    _buildDetailRow(
                      Icons.attach_money,
                      'Price',
                      '\$${delivery.price!.toStringAsFixed(2)}',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
