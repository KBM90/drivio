import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Earnings')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mar 4 - Mar 11',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                '\$205.74',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('M', style: TextStyle(fontSize: 16)),
                  Text('T', style: TextStyle(fontSize: 16)),
                  Text('W', style: TextStyle(fontSize: 16)),
                  Text('T', style: TextStyle(fontSize: 16)),
                  Text('F', style: TextStyle(fontSize: 16)),
                  Text('S', style: TextStyle(fontSize: 16)),
                  Text('S', style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Online', style: TextStyle(fontSize: 16)),
                      Text(
                        '9 h 24 m',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trips', style: TextStyle(fontSize: 16)),
                      Text(
                        '17',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Points', style: TextStyle(fontSize: 16)),
                      Text(
                        '17',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Handle see details button press
                  },
                  child: Text(
                    'See details',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
              ),
              Divider(),
              SizedBox(height: 16),
              Text(
                'Balance: \$205.74',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Payment scheduled for Mar 11',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle cash out button press
                    },
                    child: Text('Cash out'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle summary button press
                    },
                    child: Text('Summary'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'See a map of earnings trends in Minneapolis - St. Paul',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
              SizedBox(height: 24),
              Text(
                'Uber Pro Blue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Points reset Apr 30',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Earn 172 more points to achieve Gold',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
