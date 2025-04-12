// accepted_ride_panel.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcceptedRidePanel extends StatefulWidget {
  final String passengerName;
  final double passengerRating;
  final String pickupLocation;
  final String destination;
  final Function(String) onCancel;

  const AcceptedRidePanel({
    super.key,
    required this.passengerName,
    required this.passengerRating,
    required this.pickupLocation,
    required this.destination,
    required this.onCancel,
  });

  @override
  State<AcceptedRidePanel> createState() => _AcceptedRidePanelState();
}

class _AcceptedRidePanelState extends State<AcceptedRidePanel> {
  final bool _showCancelOptions = false;
  String? _selectedCancelReason;

  final List<String> _cancelReasons = [
    'Accepted trip by accident',
    'Problem with pickup route',
    'Made a wrong turn',
    'Pickup isn\'t worth it',
    'Not safe to pick up',
    'Vehicle issue',
    'More issues',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // ... implement the UI as shown in the previous example ...
              // Include all the UI elements from your screenshot
            ],
          ),
        );
      },
    );
  }
}
