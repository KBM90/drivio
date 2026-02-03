import 'package:drivio_app/common/models/flight.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FlightDetailsScreen extends StatelessWidget {
  final Flight flight;

  const FlightDetailsScreen({super.key, required this.flight});

  Color _getStatusColor() {
    if (flight.isCancelled) return Colors.red;
    if (flight.isDelayed) return Colors.orange;
    if (flight.isActive) return Colors.green;
    if (flight.isLanded) return Colors.blue;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (flight.isCancelled) return Icons.cancel;
    if (flight.isDelayed) return Icons.schedule;
    if (flight.isActive) return Icons.flight;
    if (flight.isLanded) return Icons.flight_land;
    return Icons.event;
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString == 'N/A') return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM d, yyyy • HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString == 'N/A') return 'N/A';
    try {
      final dateTime = DateTime.parse(timeString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flight.flightNumber,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              flight.airlineName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(),
                                size: 18,
                                color: _getStatusColor(),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                flight.statusDisplay.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Route visualization
                    _buildRouteVisualization(),

                    const SizedBox(height: 24),

                    // Departure details
                    _buildSectionTitle('Departure'),
                    _buildInfoCard(
                      icon: Icons.flight_takeoff,
                      title: flight.departure?.airport ?? 'Unknown Airport',
                      subtitle: flight.departure?.iata ?? 'N/A',
                      details: [
                        if (flight.departure?.terminal != null)
                          _buildDetailRow(
                            'Terminal',
                            flight.departure!.terminal!,
                          ),
                        if (flight.departure?.gate != null)
                          _buildDetailRow('Gate', flight.departure!.gate!),
                        _buildDetailRow(
                          'Scheduled',
                          _formatDateTime(flight.departure?.scheduled),
                        ),
                        if (flight.departure?.estimated != null)
                          _buildDetailRow(
                            'Estimated',
                            _formatDateTime(flight.departure?.estimated),
                          ),
                        if (flight.departure?.actual != null)
                          _buildDetailRow(
                            'Actual',
                            _formatDateTime(flight.departure?.actual),
                          ),
                        if (flight.departure?.delay != null &&
                            flight.departure!.delay! > 0)
                          _buildDetailRow(
                            'Delay',
                            '${flight.departure!.delay} minutes',
                            isWarning: true,
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Arrival details
                    _buildSectionTitle('Arrival'),
                    _buildInfoCard(
                      icon: Icons.flight_land,
                      title: flight.arrival?.airport ?? 'Unknown Airport',
                      subtitle: flight.arrival?.iata ?? 'N/A',
                      details: [
                        if (flight.arrival?.terminal != null)
                          _buildDetailRow(
                            'Terminal',
                            flight.arrival!.terminal!,
                          ),
                        if (flight.arrival?.gate != null)
                          _buildDetailRow('Gate', flight.arrival!.gate!),
                        if (flight.arrival?.baggage != null)
                          _buildDetailRow('Baggage', flight.arrival!.baggage!),
                        _buildDetailRow(
                          'Scheduled',
                          _formatDateTime(flight.arrival?.scheduled),
                        ),
                        if (flight.arrival?.estimated != null)
                          _buildDetailRow(
                            'Estimated',
                            _formatDateTime(flight.arrival?.estimated),
                          ),
                        if (flight.arrival?.actual != null)
                          _buildDetailRow(
                            'Actual',
                            _formatDateTime(flight.arrival?.actual),
                          ),
                        if (flight.arrival?.delay != null &&
                            flight.arrival!.delay! > 0)
                          _buildDetailRow(
                            'Delay',
                            '${flight.arrival!.delay} minutes',
                            isWarning: true,
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Aircraft details
                    if (flight.aircraft != null) ...[
                      _buildSectionTitle('Aircraft'),
                      _buildInfoCard(
                        icon: Icons.airplanemode_active,
                        title: 'Aircraft Information',
                        subtitle: flight.aircraft?.iata ?? 'N/A',
                        details: [
                          if (flight.aircraft?.registration != null)
                            _buildDetailRow(
                              'Registration',
                              flight.aircraft!.registration!,
                            ),
                          if (flight.aircraft?.icao != null)
                            _buildDetailRow('ICAO', flight.aircraft!.icao!),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Live tracking info
                    if (flight.live != null &&
                        flight.live!.latitude != null) ...[
                      _buildSectionTitle('Live Tracking'),
                      _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'Current Position',
                        subtitle: 'Real-time flight data',
                        details: [
                          _buildDetailRow(
                            'Latitude',
                            flight.live!.latitude!.toStringAsFixed(4),
                          ),
                          _buildDetailRow(
                            'Longitude',
                            flight.live!.longitude!.toStringAsFixed(4),
                          ),
                          if (flight.live!.altitude != null)
                            _buildDetailRow(
                              'Altitude',
                              '${flight.live!.altitude!.toStringAsFixed(0)} m',
                            ),
                          if (flight.live!.speedHorizontal != null)
                            _buildDetailRow(
                              'Speed',
                              '${flight.live!.speedHorizontal!.toStringAsFixed(0)} km/h',
                            ),
                          if (flight.live!.direction != null)
                            _buildDetailRow(
                              'Direction',
                              '${flight.live!.direction!.toStringAsFixed(0)}°',
                            ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteVisualization() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Departure
          Expanded(
            child: Column(
              children: [
                Text(
                  flight.departure?.iata ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(flight.departure?.scheduled),
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          // Arrow
          Column(
            children: [
              Icon(Icons.arrow_forward, size: 32, color: Colors.blue[700]),
              const SizedBox(height: 4),
              Text(
                flight.flightDate ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),

          // Arrival
          Expanded(
            child: Column(
              children: [
                Text(
                  flight.arrival?.iata ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(flight.arrival?.scheduled),
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> details,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...details,
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isWarning ? Colors.orange[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
