import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/driver/models/vehicle.dart';
import 'package:drivio_app/driver/services/vehicle_service.dart';
import 'package:drivio_app/driver/ui/screens/car_info_screen.dart';
import 'package:drivio_app/driver/ui/screens/driver_information_screen.dart';
import 'package:drivio_app/driver/ui/screens/payment_settings_screen.dart';
import 'package:drivio_app/driver/ui/screens/preferences_page.dart';
import 'package:drivio_app/driver/ui/screens/trip_history_screen.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Vehicle? _vehicle;
  bool _isLoadingVehicle = true;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      setState(() => _isLoadingVehicle = true);
      final vehicle = await VehicleService.getDriverVehicle();
      if (mounted) {
        setState(() {
          _vehicle = vehicle;
          _isLoadingVehicle = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading vehicle: $e');
      if (mounted) {
        setState(() => _isLoadingVehicle = false);
      }
    }
  }

  Future<void> _navigateToCarInfo() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => CarInfoScreen(vehicle: _vehicle)),
    );

    // Reload vehicle data if changes were made
    if (result == true) {
      _loadVehicle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Vehicles'),
          _buildVehicleItem(),
          const SizedBox(height: 24),
          _buildSectionHeader('Work Hub'),
          _buildListItem(
            'Driver Information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverInformationScreen(),
                ),
              );
            },
          ),
          _buildListItem(
            'Payment',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentSettingsScreen(),
                ),
              );
            },
          ),
          _buildListItem(
            'Trip History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TripHistoryScreen(),
                ),
              );
            },
          ),
          _buildListItem(
            'Preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PreferencesScreen(),
                ),
              );
            },
          ),
          _buildListItem('Documents & Verification'),
          _buildListItem('Support & Help Center'),
          _buildListItem('App Settings'),
          _buildListItem('Privacy'),
          _buildListItem('Terms & Conditions'),
          const SizedBox(height: 24),
          _buildDeleteAccountButton(context),
        ],
      ),
    );
  }

  Widget _buildVehicleItem() {
    if (_isLoadingVehicle) {
      return const Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 4.0),
        child: ListTile(
          title: Text('Loading...'),
          trailing: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final displayText = _vehicle?.displayName ?? 'Add Vehicle';
    final subtitle =
        _vehicle?.color != null ? 'Color: ${_vehicle!.color}' : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.directions_car),
        title: Text(displayText),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: _navigateToCarInfo,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildListItem(String title, {VoidCallback? onTap}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap:
            onTap ??
            () {
              // Handle item tap
            },
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: Colors.red[50],
      child: ListTile(
        leading: const Icon(Icons.delete_forever, color: Colors.red),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        onTap: () => _showDeleteConfirmation(context),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteConfirmationDialog(),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const Center(child: CircularProgressIndicator()),
          );
        }

        await AuthService.deleteAccount();

        // Navigation to login screen is handled by AuthGate/AuthState changes
        // We need to clear the navigation stack to reveal the AuthGate (which will show LoginScreen)
        if (context.mounted) {
          Navigator.pop(context); // Pop loading dialog
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop loading dialog
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
        }
      }
    }
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  const _DeleteConfirmationDialog();

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  int _countdown = 5;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    while (_countdown > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _countdown--;
        });
      }
    }
    if (mounted) {
      setState(() {
        _canDelete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Account?'),
      content: const Text(
        'Are you sure you want to delete your account? This action cannot be undone and all your data will be lost.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(_canDelete ? 'Delete' : 'Delete ($_countdown)'),
        ),
      ],
    );
  }
}
