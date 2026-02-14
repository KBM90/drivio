import 'package:drivio_app/common/widgets/cached_tile_layer.dart';
import 'package:drivio_app/common/widgets/gps_button.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:drivio_app/common/models/delivery_request.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/common/widgets/navigation_marker.dart';
import 'package:drivio_app/delivery_person/providers/delivery_person_location_provider.dart';
import 'package:drivio_app/delivery_person/services/delivery_person_service.dart';
import 'package:drivio_app/delivery_person/services/delivery_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Example screen showing how to manage delivery status and location tracking
/// This demonstrates the complete delivery workflow with status transitions
class DeliveryDetailsScreen extends StatefulWidget {
  final int deliveryId;

  const DeliveryDetailsScreen({super.key, required this.deliveryId});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  DeliveryRequest? _deliveryRequest;
  bool _isLoading = true;
  String? _error;
  final MapController _mapController = MapController();
  Map<String, dynamic>? _passengerProfile;

  @override
  void initState() {
    super.initState();
    _loadDeliveryRequest();
  }

  Future<void> _loadDeliveryRequest() async {
    try {
      final delivery = await DeliveryService.getDeliveryRequestById(
        widget.deliveryId,
      );

      // Fetch passenger profile
      final profile = await AuthService.getPassengerProfile(
        delivery.passengerId,
      );

      setState(() {
        _deliveryRequest = delivery;
        _passengerProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchCall() async {
    if (_passengerProfile == null || _passengerProfile!['phone'] == null) {
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: _passengerProfile!['phone']);
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    if (_passengerProfile == null || _passengerProfile!['phone'] == null) {
      return;
    }

    var phone = _passengerProfile!['phone'] as String;
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    final Uri launchUri = Uri.parse('https://wa.me/$cleanPhone');

    if (!await launchUrl(launchUri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  /// Get status color based on current status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'accepted':
        return Colors.blue;
      case 'picking_up':
        return Colors.orange;
      case 'picked_up':
        return Colors.purple;
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

  /// Get status icon based on current status
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Delivery #${widget.deliveryId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _deliveryRequest == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Delivery #${widget.deliveryId}')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDeliveryRequest,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final delivery = _deliveryRequest!;
    final currentStatus = delivery.status;

    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery #${widget.deliveryId}'),
        actions: [
          if (_passengerProfile != null &&
              _passengerProfile!['phone'] != null) ...[
            IconButton(
              onPressed: _launchCall,
              icon: const Icon(Icons.phone),
              tooltip: 'Call Passenger',
            ),
            IconButton(
              onPressed: _launchWhatsApp,
              icon: const Icon(Icons.chat),
              tooltip: 'WhatsApp Passenger',
            ),
          ],
        ],
      ),
      body: Consumer<DeliveryPersonLocationProvider>(
        builder: (context, locationProvider, _) {
          final isActive =
              locationProvider.isTrackingActive &&
              locationProvider.activeDeliveryId == widget.deliveryId;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status indicator
                  Card(
                    color: _getStatusColor(currentStatus).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(currentStatus),
                            color: _getStatusColor(currentStatus),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getStatusDisplayText(currentStatus),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(currentStatus),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tracking',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delivery details
                  const Text(
                    'Delivery Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (delivery.category.isNotEmpty)
                    _buildDetailRow(
                      Icons.category,
                      'Category',
                      delivery.category,
                    ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.map,
                    'Total Distance',
                    _calculateTotalDistance(
                      delivery,
                      locationProvider.currentLocation,
                    ),
                  ),
                  if (delivery.description != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.description,
                      'Description',
                      delivery.description!,
                    ),
                  ],
                  if (delivery.pickupNotes != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.store,
                      'Pickup Notes',
                      delivery.pickupNotes!,
                    ),
                  ],
                  if (delivery.dropoffNotes != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.home,
                      'Dropoff Notes',
                      delivery.dropoffNotes!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Map Section
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildMap(locationProvider),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons based on current status
                  ..._buildActionButtons(
                    context,
                    locationProvider,
                    currentStatus,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting for Acceptance';
      case 'price_negotiation':
        return 'Price Negotiation';
      case 'accepted':
        return 'Delivery Accepted';
      case 'picking_up':
        return 'Picking Up';
      case 'picked_up':
        return 'Item Picked Up';
      case 'delivering':
        return 'Delivering';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    DeliveryPersonLocationProvider locationProvider,
    String currentStatus,
  ) {
    switch (currentStatus) {
      case 'pending':
        final price = _deliveryRequest?.price ?? 0.0;
        return [
          // Accept at original price
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final deliveryPersonId =
                    await AuthService.getDeliveryPersonId();
                if (deliveryPersonId == null) {
                  throw Exception('Delivery person profile not found');
                }

                await DeliveryPersonService.acceptDeliveryRequest(
                  widget.deliveryId,
                  deliveryPersonId,
                );

                await locationProvider.startTracking(widget.deliveryId);
                await _loadDeliveryRequest();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Delivery accepted at \$$price'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.check),
            label: Text('Accept at \$$price'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          // Propose new price
          OutlinedButton.icon(
            onPressed: () => _showProposePriceDialog(context),
            icon: const Icon(Icons.attach_money),
            label: const Text('Propose New Price'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ];

      case 'price_negotiation':
        return [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  color: Colors.orange,
                  size: 32,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for Passenger Response',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Proposed: \$${_deliveryRequest?.proposedPrice ?? 0}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ];

      case 'accepted':
        return [
          ElevatedButton.icon(
            onPressed: () async {
              await _updateDeliveryStatus(locationProvider, 'picking_up');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Started pickup - On the way to store'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.directions_walk),
            label: const Text('Start Pickup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ];

      case 'picking_up':
        return [
          ElevatedButton.icon(
            onPressed: () async {
              await _updateDeliveryStatus(locationProvider, 'picked_up');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item picked up - Ready to deliver'),
                    backgroundColor: Colors.purple,
                  ),
                );
              }
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Confirm Pickup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ];

      case 'picked_up':
        return [
          ElevatedButton.icon(
            onPressed: () async {
              await _updateDeliveryStatus(locationProvider, 'delivering');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Started delivery - On the way to customer'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: const Icon(Icons.local_shipping),
            label: const Text('Start Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ];

      case 'delivering':
        return [
          ElevatedButton.icon(
            onPressed: () async {
              await locationProvider.stopTracking();
              await _loadDeliveryRequest(); // Refresh to show new status
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery completed!'),
                    backgroundColor: Colors.teal,
                  ),
                );
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.done_all),
            label: const Text('Complete Delivery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Cancel Delivery?'),
                      content: const Text(
                        'Are you sure you want to cancel this delivery?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Yes, Cancel'),
                        ),
                      ],
                    ),
              );

              if (confirm == true && context.mounted) {
                await locationProvider.stopTracking();
                await _loadDeliveryRequest(); // Refresh to show new status
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery cancelled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                }
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Delivery'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ];

      default:
        return [];
    }
  }

  Future<void> _updateDeliveryStatus(
    DeliveryPersonLocationProvider locationProvider,
    String status,
  ) async {
    if (!locationProvider.isTrackingActive ||
        locationProvider.activeDeliveryId != widget.deliveryId) {
      await locationProvider.startTracking(
        widget.deliveryId,
        initialStatus: status,
      );
    } else {
      await locationProvider.updateDeliveryStatus(
        status,
        deliveryId: widget.deliveryId,
      );
    }
    await _loadDeliveryRequest();
  }

  String _calculateTotalDistance(
    DeliveryRequest delivery,
    LatLng? currentLocation,
  ) {
    double totalDistance = delivery.distanceKm ?? 0.0;
    const distance = Distance();

    if (currentLocation != null) {
      if (delivery.pickupLocation != null &&
          delivery.pickupLocation!.latitude != null &&
          delivery.pickupLocation!.longitude != null) {
        // Distance: Me -> Pickup
        final distToPickup = distance.as(
          LengthUnit.Kilometer,
          currentLocation,
          LatLng(
            delivery.pickupLocation!.latitude!,
            delivery.pickupLocation!.longitude!,
          ),
        );
        totalDistance += distToPickup;
      } else if (delivery.deliveryLocation != null &&
          delivery.deliveryLocation!.latitude != null &&
          delivery.deliveryLocation!.longitude != null) {
        // Distance: Me -> Delivery (Direct)
        // If pickup is null, base distance is 0, so we just add distance from Me -> Delivery
        final distToDelivery = distance.as(
          LengthUnit.Kilometer,
          currentLocation,
          LatLng(
            delivery.deliveryLocation!.latitude!,
            delivery.deliveryLocation!.longitude!,
          ),
        );
        totalDistance += distToDelivery;
      }
    }

    return '${totalDistance.toStringAsFixed(1)} km';
  }

  Widget _buildMap(DeliveryPersonLocationProvider locationProvider) {
    if (_deliveryRequest == null) return const SizedBox();

    final delivery = _deliveryRequest!;
    final currentLocation = locationProvider.currentLocation;
    final markers = <Marker>[];
    final points = <LatLng>[];

    // 1. Current Location Marker
    if (currentLocation != null) {
      points.add(currentLocation);
      markers.add(
        Marker(
          point: currentLocation,
          width: 40,
          height: 40,
          child: NavigationMarker(
            heading: locationProvider.currentPosition?.heading ?? 0.0,
            color: const Color.fromARGB(255, 2, 15, 24),
            size: 30,
          ),
        ),
      );
    }

    // 2. Pickup Location Marker
    // Only show pickup in route if we haven't started delivering yet
    if (delivery.pickupLocation != null &&
        delivery.pickupLocation!.latitude != null &&
        delivery.pickupLocation!.longitude != null &&
        delivery.status != 'delivering') {
      final pickupLatLng = LatLng(
        delivery.pickupLocation!.latitude!,
        delivery.pickupLocation!.longitude!,
      );
      points.add(pickupLatLng);
      markers.add(
        Marker(
          point: pickupLatLng,
          width: 40,
          height: 40,
          child: const Icon(Icons.store, color: Colors.orange, size: 30),
        ),
      );
    }

    // 3. Delivery Location Marker
    if (delivery.deliveryLocation != null &&
        delivery.deliveryLocation!.latitude != null &&
        delivery.deliveryLocation!.longitude != null) {
      final deliveryLatLng = LatLng(
        delivery.deliveryLocation!.latitude!,
        delivery.deliveryLocation!.longitude!,
      );
      points.add(deliveryLatLng);
      markers.add(
        Marker(
          point: deliveryLatLng,
          width: 40,
          height: 40,
          child: const Icon(Icons.person, color: Colors.red, size: 30),
        ),
      );
    }

    // Determine initial center
    final initialCenter =
        points.isNotEmpty ? points.first : const LatLng(35.08, -2.33);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: initialCenter, initialZoom: 13.0),
          children: [
            CachedTileLayer(),
            // Only show polyline if accepted or active
            if ([
                  'accepted',
                  'picking_up',
                  'picked_up',
                  'delivering',
                ].contains(delivery.status) &&
                points.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    color: Colors.blue,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: GPSButton(
            mapController: _mapController,
            currentLocation: currentLocation,
            zoomLevel: 15.0,
          ),
        ),
      ],
    );
  }

  void _showProposePriceDialog(BuildContext context) {
    final priceController = TextEditingController();
    final originalPrice = _deliveryRequest?.price ?? 0.0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Propose New Price'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original Price: \$$originalPrice',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Your Proposed Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final proposedPrice = double.tryParse(priceController.text);
                  if (proposedPrice == null || proposedPrice <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid price'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    final deliveryPersonId =
                        await AuthService.getDeliveryPersonId();
                    if (deliveryPersonId == null) {
                      throw Exception('Delivery person profile not found');
                    }

                    await DeliveryPersonService.proposePrice(
                      widget.deliveryId,
                      deliveryPersonId,
                      proposedPrice,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      await _loadDeliveryRequest();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Price proposal sent: \$$proposedPrice',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Propose'),
              ),
            ],
          ),
    );
  }
}
