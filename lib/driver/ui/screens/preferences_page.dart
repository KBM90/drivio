import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _isConnectChecked = true;
  bool _isDrivioXChecked = false;
  bool _isDeliveriesChecked = false;
  bool _teenRequestsEnabled = false;
  bool _isMusicChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtering trips based on preferences',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Services Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Services',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See more',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 5,
                childAspectRatio: 1.2,
                children: [
                  _buildServiceItem(
                    title: 'Intercity',
                    icon: Icons.alt_route,
                    isChecked: _isConnectChecked,
                    onChanged:
                        (value) => setState(() => _isConnectChecked = value!),
                  ),
                  _buildServiceItem(
                    title: 'DrivioX',
                    icon: Icons.directions_car,
                    isChecked: _isDrivioXChecked,
                    onChanged:
                        (value) => setState(() => _isDrivioXChecked = value!),
                  ),
                  _buildServiceItem(
                    title: 'Deliveries',
                    icon: Icons.delivery_dining,
                    isChecked: _isDeliveriesChecked,
                    onChanged:
                        (value) =>
                            setState(() => _isDeliveriesChecked = value!),
                  ),
                  _buildServiceItem(
                    title: 'Smoking',
                    icon: Icons.smoking_rooms,
                    isChecked: _isMusicChecked,
                    onChanged:
                        (value) => setState(() => _isMusicChecked = value!),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Trip Filters Section
              Text(
                'Trip filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _switchListTile(
                title: "Teen requests",
                ischecked: _teenRequestsEnabled,
                onChanged:
                    (value) => setState(() => _teenRequestsEnabled = value!),
              ),
              const SizedBox(height: 24),

              // Reset Button
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Reset',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required String title,
    required IconData icon,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Checkbox(
                  value: isChecked,
                  onChanged: onChanged,
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchListTile({
    required String title,
    required bool ischecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        value: ischecked,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }
}
