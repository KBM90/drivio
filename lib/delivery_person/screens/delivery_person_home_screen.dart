import 'package:drivio_app/common/providers/notification_provider.dart';
import 'package:drivio_app/common/screens/notifications_screen.dart';
import 'package:drivio_app/delivery_person/screens/delivery_person_settings_screen.dart';
import 'package:drivio_app/delivery_person/providers/delivery_person_location_provider.dart';
import 'package:drivio_app/delivery_person/screens/delivery_history_screen.dart';
import 'package:drivio_app/delivery_person/screens/delivery_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryPersonHomeScreen extends StatefulWidget {
  const DeliveryPersonHomeScreen({super.key});

  @override
  State<DeliveryPersonHomeScreen> createState() =>
      _DeliveryPersonHomeScreenState();
}

class _DeliveryPersonHomeScreenState extends State<DeliveryPersonHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    DeliveryRequestsScreen(),
    DeliveryHistoryScreen(),
    DeliveryPersonSettingsScreen(),
  ];

  static const List<String> _titles = <String>[
    'Delivery Requests',
    'Delivery History',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    // Update delivery person location once when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationProvider = context.read<DeliveryPersonLocationProvider>();
      locationProvider.updateCurrentLocation();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _selectedIndex == 2
              ? null
              : AppBar(
                automaticallyImplyLeading: false, // Remove back button
                title: Text(_titles[_selectedIndex]),
                actions: [
                  Consumer<NotificationProvider>(
                    builder: (context, notifProvider, _) {
                      return Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const NotificationsScreen(),
                                ),
                              );
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
