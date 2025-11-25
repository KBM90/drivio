import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Vehicles'),
          _buildListItem('Kia K5'),
          const SizedBox(height: 24),
          _buildSectionHeader('Work Hub'),
          _buildListItem('Documents'),
          _buildListItem('Payment'),
          _buildListItem('Plus Card'),
          _buildListItem('Tax Info'),
          _buildListItem('Manage Uber account'),
          _buildListItem('Edit Address'),
          _buildListItem('Insurance'),
          _buildListItem('Privacy'),
          _buildListItem('App Settings'),
          const SizedBox(height: 24),
          _buildDeleteAccountButton(context),
        ],
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

  Widget _buildListItem(String title) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(title),
        onTap: () {
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
