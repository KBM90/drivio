import 'package:flutter/material.dart';

import 'add_service_screen.dart';
import 'my_services_screen.dart';

import 'provider_bookings_screen.dart';
import 'provider_settings_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;
  VoidCallback? _refreshServices;

  List<Widget> get _screens => [
    MyServicesScreen(
      onRefreshCallback: (callback) => _refreshServices = callback,
    ), // My Services
    const ProviderBookingsScreen(), // My Bookings
    const ProviderSettingsScreen(), // Settings (Profile + App Settings)
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/app/app_logo_without_background.png',
          height: 70,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        onTap: _onItemTapped,
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddServiceScreen()),
                  );
                  // Refresh services list if a service was added
                  if (result == true && _refreshServices != null) {
                    _refreshServices!();
                  }
                },
                backgroundColor: Colors.green,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
