import 'package:flutter/material.dart';
import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/passenger/widgets/passenger_bottom_nav_bar.dart';

class PassengerActivityScreen extends StatelessWidget {
  const PassengerActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ——— Title ———
              const Text(
                'Activity',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ——— Upcoming section ———
              const Text(
                'Upcoming',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Empty‑state card for no upcoming trips
              Row(
                children: [
                  // Text + link
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You have no upcoming trips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            // e.g. go to booking or services
                            Navigator.pushNamed(
                              context,
                              AppRoutes.passengerServices,
                            );
                          },
                          child: const Text(
                            'Reserve your trip →',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Illustration/icon
                  Icon(
                    Icons.event_note_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ——— Past section header ———
              Row(
                children: [
                  const Text(
                    'Past',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(Icons.filter_list, color: Colors.black54),
                ],
              ),
              const SizedBox(height: 12),

              // Empty‑state text for no past trips
              const Text(
                "You don't have any recent activity",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),

      // ——— bottom nav ———
      bottomNavigationBar: const PassengerBottomNavBarWidget(),
    );
  }
}
