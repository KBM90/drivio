import 'package:drivio_app/common/widgets/cancel_trip_dialog.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CancelTripWidget extends StatefulWidget {
  const CancelTripWidget({super.key});

  @override
  State<CancelTripWidget> createState() => _CancelTripWidgetState();
}

class _CancelTripWidgetState extends State<CancelTripWidget> {
  String? _selectedReason;
  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          heroTag: "on_trip_button", // Unique hero tag
          onPressed: () async {
            final confirmed = await showCancelTripDialog(context, true);

            if (confirmed == null) return; // Dialog was cancelled or no reason

            try {
              await DriverService.cancelTrip(_selectedReason!);
              await driverProvider.toggleStatus('inactive');
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(driverProvider.statusMessage!),
                  backgroundColor: const Color.fromARGB(255, 5, 105, 171),
                ),
              );
            } catch (e) {
              if (!context.mounted) return;

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
