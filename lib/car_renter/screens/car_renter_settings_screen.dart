import 'package:flutter/material.dart';
import 'package:drivio_app/car_renter/models/car_renter.dart';
import 'package:drivio_app/car_renter/screens/car_renter_profile_screen.dart';
import 'package:drivio_app/common/screens/app_settings_screen.dart';
import 'package:drivio_app/common/l10n/app_localizations.dart';

class CarRenterSettingsScreen extends StatelessWidget {
  final CarRenter carRenter;

  const CarRenterSettingsScreen({super.key, required this.carRenter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.person,
            title: AppLocalizations.of(context)?.account ?? 'Account',
            subtitle: AppLocalizations.of(context)?.manageProfileBusinessDetails ?? 'Manage your profile and business details',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => CarRenterProfileScreen(carRenter: carRenter),
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.settings,
            title: AppLocalizations.of(context)?.settings ?? 'App Settings',
            subtitle: AppLocalizations.of(context)?.themeLanguagePreferences ?? 'Theme, language, and other preferences',
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
