import 'package:drivio_app/common/screens/car_rental_screen.dart';
import 'package:drivio_app/common/screens/flight_filter_screen.dart';
import 'package:drivio_app/passenger/widgets/passenger_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

class PassengerServicesScreen extends StatelessWidget {
  const PassengerServicesScreen({super.key});

  // Define your service entries here
  final List<Map<String, dynamic>> _services = const [
    // Core ride services
    {'icon': Icons.directions_car, 'label': 'Ride', 'promo': false},
    {'icon': Icons.car_rental, 'label': 'Car rental', 'promo': false},
    {'icon': Icons.food_bank, 'label': 'Food', 'promo': false},
    {'icon': Icons.flight_takeoff, 'label': 'Airport', 'promo': false},

    // Time-based services
    {'icon': Icons.event_note, 'label': 'Reserve', 'promo': false},
    {'icon': Icons.timer, 'label': 'Hourly', 'promo': false},
    {'icon': Icons.alt_route, 'label': 'Intercity', 'promo': true},

    // Delivery services
    {'icon': Icons.local_shipping, 'label': 'Delivery', 'promo': false},
    {'icon': Icons.inventory_2, 'label': 'Package', 'promo': false},

    // Special services
    // {'icon': Icons.pets, 'label': 'Pet-friendly', 'promo': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1) Title + subtitle
              const Text(
                'Services',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Go anywhere, get anything',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // 2) Grid of service cards
              Expanded(
                child: GridView.builder(
                  itemCount: _services.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, i) {
                    final svc = _services[i];
                    return _ServiceCard(
                      icon: svc['icon'] as IconData,
                      label: svc['label'] as String,
                      promo: svc['promo'] as bool,
                      onTap: () {
                        // Navigate to Car Rental screen
                        if (svc['label'] == 'Car rental') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CarRentalScreen(),
                            ),
                          );
                        } else if (svc['label'] == 'Airport') {
                          // Navigate to Flight Filter screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FlightFilterScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${svc['label']} - Coming Soon!'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // 3) bottom nav
      bottomNavigationBar: const PassengerBottomNavBarWidget(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool promo;
  final VoidCallback? onTap;

  const _ServiceCard({
    required this.icon,
    required this.label,
    this.promo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Badge + icon
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                child: Icon(icon, size: 28, color: Colors.black87),
              ),
              if (promo)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Promo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Label
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
            maxLines: 1, // ← never wrap
            overflow: TextOverflow.ellipsis, // ←
          ),
        ],
      ),
    );
  }
}
