import 'package:drivio_app/driver/providers/driver_provider.dart';
import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:drivio_app/driver/services/change_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GoOfflineButton extends StatefulWidget {
  const GoOfflineButton({super.key});

  @override
  State<GoOfflineButton> createState() => _GoOfflineButtonState();
}

class _GoOfflineButtonState extends State<GoOfflineButton> {
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
            try {
              final message = await ChangeStatus().goOffline();

              if (!context.mounted) return;

              // ✅ Only update status if no exception was thrown
              driverProvider.toggleStatus('inactive');

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message!),
                  backgroundColor: const Color.fromARGB(255, 245, 5, 5),
                ),
              );
            } catch (e) {
              // ❌ If an error occurs, don't update driverStatus
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Colors.red,
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
