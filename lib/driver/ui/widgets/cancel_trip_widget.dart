import 'package:drivio_app/common/helpers/snack_bar_helper.dart';
import 'package:drivio_app/common/widgets/cancel_trip_dialog.dart';
import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/services/ride_request_services.dart';
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
    final driverProvider = Provider.of<DriverProvider>(context);

    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          heroTag: "on_trip_button", // Unique hero tag
          onPressed: () async {
            final selectedReason = await showCancelTripDialog(context, true);

            if (selectedReason == null) {
              return;
            } // Dialog was cancelled or no reason// Dialog was cancelled or no reason

            try {
              await RideRequestService.cancelTrip(selectedReason);
              await driverProvider.toggleStatus('inactive');
              if (!context.mounted) return;

              showSnackBar(context, driverProvider.statusMessage!);
            } catch (e) {
              if (!context.mounted) return;

              showSnackBar(context, e.toString());
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
