import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/driver/services/trip_history_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final TripHistoryService _tripHistoryService = TripHistoryService();
  List<RideRequest> _trips = [];
  bool _isLoading = true;
  int _totalTrips = 0;

  @override
  void initState() {
    super.initState();
    _loadTripHistory();
  }

  Future<void> _loadTripHistory() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _tripHistoryService.getTripHistory(),
        _tripHistoryService.getTripCount(),
      ]);

      if (mounted) {
        setState(() {
          _trips = results[0] as List<RideRequest>;
          _totalTrips = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading trip history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        actions: [
          if (_totalTrips > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  '$_totalTrips trips',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _trips.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadTripHistory,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    return _buildTripCard(_trips[index]);
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No trips yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed trips will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(RideRequest trip) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final passengerName = trip.passenger.user?.name ?? 'Unknown';
    final statusColor = _getStatusColor(trip.status);
    final statusText = _getStatusText(trip.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showTripDetails(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Date and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(trip.createdAt ?? DateTime.now()),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Passenger Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      passengerName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          passengerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          trip.transportType?.name ?? 'Standard',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Trip Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem(
                    Icons.straighten,
                    '${trip.distanceKm?.toStringAsFixed(1) ?? '0'} km',
                  ),
                  _buildDetailItem(
                    Icons.access_time,
                    '${trip.estimatedTimeMin ?? 0} min',
                  ),
                ],
              ),
              const Divider(height: 24),

              // Fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fare',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '${trip.price?.toStringAsFixed(2) ?? '0.00'} MAD',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled_by_driver':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled_by_driver':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }

  void _showTripDetails(RideRequest trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Trip Details',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      'Passenger',
                      trip.passenger.user?.name ?? 'Unknown',
                    ),
                    _buildDetailRow(
                      'Phone',
                      trip.passenger.user?.phone ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Transport Type',
                      trip.transportType?.name ?? 'Standard',
                    ),
                    _buildDetailRow(
                      'Distance',
                      '${trip.distanceKm?.toStringAsFixed(2) ?? '0'} km',
                    ),
                    _buildDetailRow(
                      'Duration',
                      '${trip.estimatedTimeMin ?? 0} minutes',
                    ),
                    _buildDetailRow(
                      'Fare',
                      '${trip.price?.toStringAsFixed(2) ?? '0.00'} MAD',
                    ),
                    _buildDetailRow('Status', _getStatusText(trip.status)),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
