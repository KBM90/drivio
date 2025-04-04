import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:drivio_app/driver/services/change_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CancelTripWidget extends StatefulWidget {
  const CancelTripWidget({super.key});

  @override
  State<CancelTripWidget> createState() => _CancelTripWidgetState();
}

class _CancelTripWidgetState extends State<CancelTripWidget> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          heroTag: "on_trip_button", // Unique hero tag
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Confirm Cancel Trip"),
                  content: const Text(
                    "Are you sure you want to cancel the trip?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false), // Cancel
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true), // Confirm
                      child: const Text("Yes"),
                    ),
                  ],
                );
              },
            );

            if (confirmed != true) return; // User cancelled the dialog

            try {
              final message = await ChangeStatus().goOffline();

              if (!context.mounted) return;

              Provider.of<DriverStatusProvider>(
                context,
                listen: false,
              ).toggleStatus('inactive');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message!),
                  backgroundColor: const Color.fromARGB(255, 5, 105, 171),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          // Go Online Action
          backgroundColor: const Color.fromARGB(255, 4, 186, 210),
          elevation: 3,
          shape: CircleBorder(),
          child: Text(
            "On Trip",
            style: TextStyle(fontSize: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
