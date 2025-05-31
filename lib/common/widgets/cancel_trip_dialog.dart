import 'package:flutter/material.dart';

Future<String?> showCancelTripDialog(BuildContext context, bool isDriver) {
  String? selectedReason;
  final List<String> driverCancellationReasons = [
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
  final List<String> passengerCancellationReasons = [
    'Driver is not moving',
    'Driver is too far',
    'Driver not responding',
    'Incorrect driver or vehicle',
    'I no longer need a ride',
    'Found an alternative transport',
    'Personal emergency',
    'Trip price too high',
    'Driver behavior concerns',
    'Other (please specify)',
  ];

  final TextEditingController otherController = TextEditingController();

  return showDialog<String>(
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
                    value: selectedReason,
                    hint: const Text('Select reason'),
                    items:
                        isDriver
                            ? driverCancellationReasons.map((String reason) {
                              return DropdownMenuItem<String>(
                                value: reason,
                                child: Text(reason),
                              );
                            }).toList()
                            : passengerCancellationReasons.map((String reason) {
                              return DropdownMenuItem<String>(
                                value: reason,
                                child: Text(reason),
                              );
                            }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedReason = value;
                      });
                    },
                  ),
                  if (selectedReason == 'Other (please specify)')
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextFormField(
                        controller: otherController,
                        decoration: const InputDecoration(
                          labelText: 'Please specify',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () {
                  if (selectedReason == 'Other (please specify)') {
                    Navigator.pop(
                      context,
                      otherController.text.trim().isNotEmpty
                          ? otherController.text.trim()
                          : null,
                    );
                  } else {
                    Navigator.pop(context, selectedReason);
                  }
                },
                child: const Text("Yes"),
              ),
            ],
          );
        },
      );
    },
  );
}
