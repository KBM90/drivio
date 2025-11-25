import 'package:drivio_app/common/models/ride_request.dart';
import 'package:drivio_app/common/providers/notification_provider.dart';
import 'package:drivio_app/passenger/providers/passenger_ride_request_provider.dart';
import 'package:drivio_app/passenger/screens/passenger_map_view.dart';
import 'package:drivio_app/passenger/widgets/passenger_bottom_nav_bar.dart';
import 'package:drivio_app/passenger/widgets/ride_request_status_card.dart';
import 'package:flutter/material.dart';
import 'package:drivio_app/passenger/widgets/search_bar.dart';
import 'package:drivio_app/passenger/screens/product_categories_screen.dart';
import 'package:provider/provider.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  bool showRides = true;
  RideRequest? currentRideRequest;
  late PageController _pageController;

  final suggestions = [
    {'icon': Icons.directions_car, 'label': 'Trip'},
    {'icon': Icons.fastfood, 'label': 'Food'},
    {'icon': Icons.train, 'label': 'Transit'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    // Schedule a callback after the first frame to safely access the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<PassengerRideRequestProvider>(
        context,
        listen: false,
      );
      prov.fetchCurrentRideRequest();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onToggle(bool isRides) {
    setState(() {
      showRides = isRides;
    });
    _pageController.animateToPage(
      isRides ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PassengerRideRequestProvider>(
          builder: (context, provider, child) {
            // ✅ Handle loading state or if data hasn't been fetched yet (e.g. provider recreation)
            if (provider.isLoading || !provider.hasFetched) {
              if (!provider.hasFetched && !provider.isLoading) {
                // Trigger fetch if not already loading
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  provider.fetchCurrentRideRequest();
                });
              }
              return const Center(child: CircularProgressIndicator());
            }

            // ✅ If there's a current ride request → show only the RideRequestStatusWidget
            if (provider.currentRideRequest != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: RideRequestStatusWidget(
                  rideRequest: provider.currentRideRequest!,
                ),
              );
            }

            // ✅ Otherwise show the full “default” UI (search bar + suggestions)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1) Top toggle: Rides / Delivery + Notification Icon
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
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
                      // Notification Icon
                      Consumer<NotificationProvider>(
                        builder: (context, notifProvider, _) {
                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {
                                  // Navigate to notifications screen (to be implemented)
                                  // For now just mark all as read for demo or show modal
                                  // Navigator.pushNamed(context, '/notifications');
                                },
                              ),
                              if (notifProvider.unreadCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 14,
                                    ),
                                    child: Text(
                                      '${notifProvider.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // PageView for sliding content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        showRides = index == 0;
                      });
                    },
                    children: [
                      // Page 0: Rides View
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2) Search bar
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const PassengerMapScreen(),
                                    ),
                                  );
                                },
                                child: const SearchBarWidget(),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Suggestions Header
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'Suggestions',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemCount: suggestions.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(width: 16),
                                itemBuilder: (context, i) {
                                  final item = suggestions[i];
                                  return Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: Colors.grey.shade200,
                                        child: Icon(
                                          item['icon'] as IconData,
                                          size: 28,
                                        ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Container(
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.blue[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -20,
                                      top: -20,
                                      child: Icon(
                                        Icons.fireplace,
                                        size: 120,
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              'Ride with Drivio →',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 16,
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

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Page 1: Delivery View
                      const DeliveryCategoriesView(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const PassengerBottomNavBarWidget(),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool isRides) {
    final selected = (isRides && showRides) || (!isRides && !showRides);

    return GestureDetector(
      onTap: () => _onToggle(isRides),
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
