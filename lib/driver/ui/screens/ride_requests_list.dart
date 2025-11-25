import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:drivio_app/driver/models/driver.dart';
import 'package:drivio_app/driver/services/change_status.dart';
import 'package:drivio_app/driver/services/ride_request_listener.dart';
import 'package:drivio_app/driver/services/ride_request_services.dart';
import 'package:flutter/material.dart';

class RideRequestsList extends StatefulWidget {
  final Driver driver;
  const RideRequestsList({super.key, required this.driver});

  @override
  State<RideRequestsList> createState() => _RideRequestsListState();
}

class _RideRequestsListState extends State<RideRequestsList> {
  final RideRequestListener _listener = RideRequestListener();
  List<Map<String, dynamic>> _nearbyRideRequests = [];

  bool _isListening = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startListeningToRideRequests();
  }

  Future<void> _startListeningToRideRequests() async {
    if (_isListening) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ChangeStatus().goOnline();
      await _listener.startListening(
        // Callback when nearby ride requests are found
        onNearbyRideRequests: (nearbyRides) {
          setState(() {
            _nearbyRideRequests = nearbyRides;
            _isLoading = false;
          });

          if (nearbyRides.isNotEmpty) {
            print('🔔 ${nearbyRides.length} nearby ride requests found!');
            _showNewRideNotification(nearbyRides.length);
          }
        },

        // Error callback
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
            _isLoading = false;
            _isListening = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );

      setState(() {
        _isListening = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Listening for rides within ${_listener.driverRange?.toStringAsFixed(1)} km',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isListening = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start listening: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNewRideNotification(int count) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔔 $count new ride request(s) nearby!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Scroll to top or navigate to requests
          },
        ),
      ),
    );
  }

  void _stopListening() {
    _listener.stopListening();
    setState(() {
      _isListening = false;
      _nearbyRideRequests = [];
    });
  }

  @override
  void dispose() {
    _listener.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        // title: Text('Available Rides'),
        actions: [
          if (_listener.driverRange != null)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Range: ${_listener.driverRange!.toStringAsFixed(1)} km',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              _isListening
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: _isListening ? Colors.green : Colors.grey,
            ),
            onPressed: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListeningToRideRequests();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color:
                _isListening
                    ? Colors.green
                    : (_errorMessage != null ? Colors.red : Colors.grey),
            child: Row(
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    _isListening
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: Colors.white,
                  ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isLoading
                        ? 'Loading...'
                        : _errorMessage != null
                        ? 'Error: $_errorMessage'
                        : _isListening
                        ? 'Listening for ride requests...'
                        : 'Not listening',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _startListeningToRideRequests,
                  ),
              ],
            ),
          ),

          // Nearby ride requests list
          Expanded(
            child:
                _nearbyRideRequests.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isListening
                                ? Icons.search
                                : Icons.notifications_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            _isListening
                                ? 'No ride requests nearby'
                                : 'Start listening to see ride requests',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          if (!_isListening)
                            Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.play_arrow),
                                label: Text('Start Listening'),
                                onPressed: _startListeningToRideRequests,
                              ),
                            ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async {
                        await _listener.refreshDriverData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Driver data refreshed')),
                        );
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: _nearbyRideRequests.length,
                        itemBuilder: (context, index) {
                          final ride = _nearbyRideRequests[index];
                          final data = ride['data'] as Map<String, dynamic>;
                          final distance = ride['distance'] as double;

                          // Parse pickup location
                          Map<String, double>? pickupCoords;
                          if (data['pickup_location'] is String) {
                            pickupCoords = GeolocatorHelper.parsePostGISPoint(
                              data['pickup_location'],
                            );
                          } else {
                            pickupCoords = GeolocatorHelper.parseGeoJSON(
                              data['pickup_location'],
                            );
                          }

                          // Parse dropoff location
                          Map<String, double>? dropOffCoords;
                          if (data['dropoff_location'] is String) {
                            dropOffCoords = GeolocatorHelper.parsePostGISPoint(
                              data['dropoff_location'],
                            );
                          } else {
                            dropOffCoords = GeolocatorHelper.parseGeoJSON(
                              data['dropoff_location'],
                            );
                          }

                          final pickupLat = pickupCoords?['latitude'] ?? 0.0;
                          final pickupLng = pickupCoords?['longitude'] ?? 0.0;
                          final dropOffLat = dropOffCoords?['latitude'] ?? 0.0;
                          final dropOffLng = dropOffCoords?['longitude'] ?? 0.0;

                          final pickupPlaceName = OSRMService().getPlaceName(
                            pickupLat,
                            pickupLng,
                          );
                          final dropOffPlaceName = OSRMService().getPlaceName(
                            dropOffLat,
                            dropOffLng,
                          );

                          return Card(
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  '${distance.toStringAsFixed(1)}\nkm',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              title: Text(
                                pickupPlaceName.toString(),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(dropOffPlaceName.toString()),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        _formatTimestamp(data['createdAt']),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed:
                                    () => _acceptRide(
                                      ride['id'].toString(),
                                      widget.driver.id!,
                                      dropOffLat,
                                      dropOffLng,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Accept'),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    try {
      DateTime dateTime;
      if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Unknown';
      }

      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _acceptRide(
    String rideId,
    int driverId,
    double latitude,
    double longitude,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // change driver status

      // Update ride request
      await RideRequestService.acceptRideRequest(
        int.parse(rideId),
        latitude,
        longitude,
      );
      await ChangeStatus().onTrip();
      if (!mounted) return;
      // Close loading dialog
      Navigator.of(context).pop();

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Ride accepted!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to ride details or remove from list
      setState(() {
        _nearbyRideRequests.removeWhere((ride) => ride['id'] == rideId);
      });
    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting ride: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
