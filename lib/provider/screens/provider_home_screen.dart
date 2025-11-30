import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../common/screens/login_screen.dart';
import 'add_service_screen.dart';
import 'my_services_screen.dart';

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
    const Center(child: Text('My Bookings')), // Placeholder for Bookings
    const Center(child: Text('Profile')), // Placeholder for Profile
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
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
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
