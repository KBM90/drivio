import 'package:drivio_app/driver/providers/driver_status_provider.dart';
import 'package:drivio_app/driver/screens/widgets/preferences_button.dart';
import 'package:drivio_app/driver/screens/widgets/recommanded_for_you_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1, // Start small
      minChildSize: 0.1, // Minimum height
      maxChildSize: 1, // Maximum height
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 244, 241, 241),
            borderRadius: const BorderRadius.vertical(top: Radius.zero),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(120),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ ListView starts AFTER the Red Bar
              Flexible(
                child: ListView(
                  controller: scrollController,
                  shrinkWrap: true,
                  children: [
                    // ✅ Move the Red Bar Here (OUTSIDE ListView)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 1,
                        vertical: 0,
                      ),
                      color: const Color.fromARGB(255, 244, 241, 241),
                      child: Consumer<DriverStatusProvider>(
                        builder: (context, provider, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PreferencesButton(),
                              Text(
                                provider.driverStatus
                                    ? "You're online"
                                    : "You're offline",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              RecommandedForYouButton(
                                onPressed: () {
                                  print("Toggle clicked");
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.car_repair, color: Colors.blue),
                      title: Text("Get 10-40% off car services"),
                      subtitle: Text("Save on maintenance & repair"),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                    ListTile(
                      leading: Icon(Icons.local_offer, color: Colors.green),
                      title: Text("Enjoy more benefits with Uber Pro"),
                      subtitle: Text("Exclusive savings and discounts"),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
