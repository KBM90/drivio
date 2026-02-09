import 'package:drivio_app/common/screens/app_settings_screen.dart';
import 'package:drivio_app/delivery_person/screens/delivery_person_account_screen.dart';
import 'package:drivio_app/delivery_person/screens/delivery_person_vehicle_screen.dart';
import 'package:flutter/material.dart';

class DeliveryPersonSettingsScreen extends StatelessWidget {
  const DeliveryPersonSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Account'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Manage your account details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeliveryPersonAccountScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Vehicle'),
          _buildSettingsTile(
            context,
            icon: Icons.directions_car_outlined,
            title: 'Vehicle Details',
            subtitle: 'Manage your vehicle information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeliveryPersonVehicleScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'General'),
          _buildSettingsTile(
            context,
            icon: Icons.settings_outlined,
            title: 'App Settings',
            subtitle: 'Theme, language, and other preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
