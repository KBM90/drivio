import 'package:flutter/material.dart';

class PreferencesModal extends StatelessWidget {
  const PreferencesModal({super.key});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 1, // Adjust the height of the modal
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Preferences",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            // Filtering trips notice
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Filtering trips based on preferences"),
            ),

            // Services Section
            const Text(
              "Services",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildServiceCard("Connect", Icons.local_shipping, true),
                _buildServiceCard("Deliveries", Icons.delivery_dining, false),
                _buildServiceCard("UberX", Icons.directions_car, true),
                _buildDisabledCard("Sign up for Shop & Pay orders"),
              ],
            ),

            const SizedBox(height: 20),

            // Trip Filters Section
            const Text(
              "Trip filters",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Teen requests"),
              subtitle: const Text("Off"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {}, // Add action here
            ),

            const Spacer(),

            // Reset Button
            Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  "Reset",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, bool isSelected) {
    return Container(
      width: 150,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? Colors.black : Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30),
                const SizedBox(height: 5),
                Text(title),
              ],
            ),
          ),
          if (isSelected)
            const Positioned(
              top: 5,
              right: 5,
              child: Icon(Icons.check_box, color: Colors.black),
            ),
        ],
      ),
    );
  }

  Widget _buildDisabledCard(String title) {
    return Container(
      width: 150,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ),
    );
  }
}
