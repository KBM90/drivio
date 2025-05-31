import 'package:drivio_app/driver/providers/driver_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GoOfflineButton extends StatelessWidget {
  const GoOfflineButton({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          heroTag: "stop_button", // Unique hero tag
          onPressed: () async {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            try {
              // if (!context.mounted) return;

              // ✅ Only update status if no exception was thrown
              await driverProvider.toggleStatus('inactive');

              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(driverProvider.statusMessage!),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              // ❌ If an error occurs, don't update driverStatus
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(driverProvider.statusMessage!),
                  backgroundColor: const Color.fromARGB(255, 242, 5, 5),
                ),
              );
            }
          }, // Go Online Action
          backgroundColor: const Color.fromARGB(255, 236, 4, 4),
          elevation: 3,
          shape: CircleBorder(),
          child: Text(
            "Stop",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
