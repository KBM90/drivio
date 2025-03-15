import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Vehicles'),
          _buildListItem('Kia K5'),
          SizedBox(height: 24),
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
}
