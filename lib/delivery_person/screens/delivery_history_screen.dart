import 'package:flutter/material.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: const TabBar(
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildHistoryList('Pending', Colors.orange),
                _buildHistoryList('Completed', Colors.green),
                _buildHistoryList('Cancelled', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(String status, Color color) {
    return ListView.builder(
      itemCount: 3, // Placeholder count
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.local_shipping, color: color),
            ),
            title: Text('Delivery #${2000 + index}'),
            subtitle: Text('Date: ${DateTime.now().toString().split(' ')[0]}'),
            trailing: Chip(
              label: Text(status, style: TextStyle(color: color, fontSize: 12)),
              backgroundColor: color.withOpacity(0.1),
            ),
          ),
        );
      },
    );
  }
}
