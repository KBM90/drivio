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
  final List<String> _cancellationReasons = [
    'Passenger requested cancellation',
    'Passenger not responding',
    'Passenger location incorrect',
    'Vehicle issues',
    'Personal emergency',
    'Traffic conditions too severe',
    'Safety concerns',
    'Payment method issues',
    'Passenger behavior concerns',
    'Other (please specify)',
  ];
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
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                      title: const Text("Cancel Trip"),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Please select the reason for cancellation:",
                              style: TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedReason,
                              hint: const Text('Select reason'),
                              items:
                                  _cancellationReasons.map((String reason) {
                                    return DropdownMenuItem<String>(
                                      value: reason,
                                      child: Text(reason),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedReason = value;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Please select a reason'
                                          : null,
                            ),
                            if (_selectedReason == 'Other (please specify)')
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Please specify',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    _selectedReason = value;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed:
                              () => Navigator.pop(context, false), // Cancel
                          child: const Text("No"),
                        ),
                        TextButton(
                          onPressed:
                              () => Navigator.pop(context, true), // Confirm
                          child: const Text("Yes"),
                        ),
                      ],
                    );
                  },
                );
              },
            );
            if (confirmed != true) return; // User cancelled the dialog

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
