import 'package:drivio_app/passenger/widgets/passenger_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

class PassengerServicesScreen extends StatelessWidget {
  const PassengerServicesScreen({Key? key}) : super(key: key);

  // Define your service entries here
  final List<Map<String, dynamic>> _services = const [
    {'icon': Icons.directions_car, 'label': 'Trip', 'promo': false},
    {'icon': Icons.car_repair, 'label': 'Car hire', 'promo': false},
    {'icon': Icons.phone_android, 'label': 'Top‑up', 'promo': true},
    {'icon': Icons.two_wheeler, 'label': '2 Wheels', 'promo': false},
    {'icon': Icons.local_shipping, 'label': 'Charter', 'promo': false},
    {'icon': Icons.pool, 'label': 'Carpool', 'promo': false},
    {'icon': Icons.timer, 'label': 'Hourly', 'promo': false},
    {'icon': Icons.event_note, 'label': 'Reserve', 'promo': false},
    {'icon': Icons.explore, 'label': 'Explore', 'promo': true},
    {'icon': Icons.storefront, 'label': 'Store pick‑up', 'promo': false},
    {'icon': Icons.inventory_2, 'label': 'Package', 'promo': false},
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

  const _ServiceCard({
    Key? key,
    required this.icon,
    required this.label,
    this.promo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
