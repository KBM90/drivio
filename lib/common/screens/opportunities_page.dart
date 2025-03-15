import 'package:flutter/material.dart';

class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Opportunities')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildEventCard(
            time: '2:00 PM - 3:00 PM',
            title: 'MSHSL Boys Hockey State Tournament - Session 1',
            location: 'Xcel Energy Center',
            type: 'Sporting Event',
          ),
          SizedBox(height: 16),
          _buildEventCard(
            time: '8:30 PM - 9:30 PM',
            title:
                'NCAA Division I (W) - Division 1st round - Purdue vs Northwestern',
            location: 'Target Center',
            type: 'Sporting Event',
          ),
          SizedBox(height: 16),
          _buildEventCard(
            time: '9:00 PM - 10:00 PM',
            title: 'MSHSL Boys Hockey State Tournament - Session 2',
            location: 'Xcel Energy Center',
            type: 'Sporting Event',
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required String time,
    required String title,
    required String location,
    required String type,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(location, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text(type, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Handle save button press
                },
                child: Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
