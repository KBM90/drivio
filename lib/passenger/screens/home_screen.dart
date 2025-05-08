import 'package:drivio_app/passenger/widgets/passenger_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:drivio_app/passenger/widgets/search_bar.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({Key? key}) : super(key: key);

  @override
  _PassengerHomeScreenState createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  bool showRides = true;

  final suggestions = [
    {'icon': Icons.directions_car, 'label': 'Trip'},
    {'icon': Icons.fastfood, 'label': 'Food'},
    {'icon': Icons.train, 'label': 'Transit'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) Top toggle: Rides / Eats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Each Expanded takes 50% of the row
                  Expanded(
                    child: _buildToggleButton(
                      'Rides',
                      Icons.directions_car,
                      true,
                    ),
                  ),
                  Expanded(
                    child: _buildToggleButton(
                      'Delivery',
                      Icons.delivery_dining,
                      false,
                    ),
                  ),
                ],
              ),
            ),

            // 2) Search bar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SearchBarWidget(),
            ),

            const SizedBox(height: 24),

            // 3) Suggestions header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Suggestions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4) Suggestions icons
            SizedBox(
              height: 100,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final item = suggestions[i];
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        child: Icon(item['icon'] as IconData, size: 28),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['label'] as String,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 5) Promo banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.blue[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    // Fireworks illustration, you can swap for your own asset
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.fireplace,
                        size: 120,
                        color: Colors.orangeAccent,
                      ),
                    ),

                    // Text + arrow
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Get out and about',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Ride with Uber →',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6) fill the rest
            const Expanded(child: SizedBox()),
          ],
        ),
      ),

      // 7) bottom navigation
      bottomNavigationBar: const PassengerBottomNavBarWidget(),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool isRides) {
    final selected = (isRides && showRides) || (!isRides && !showRides);

    return GestureDetector(
      onTap: () => setState(() => showRides = isRides),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.center, // center the Row & underline
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // center icon + text
            children: [
              Icon(
                icon,
                color: selected ? Colors.black : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.black : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 40,
            color: selected ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
