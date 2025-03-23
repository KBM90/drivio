import 'package:drivio_app/driver/models/wallet.dart';
import 'package:drivio_app/driver/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final Wallet? wallet = walletProvider.wallet; // Get wallet data
    return Scaffold(
      appBar: AppBar(title: Text('Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Balance',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                wallet != null ? wallet.balance.toString() : "Loading...",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Payout scheduled: March 11',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle cash out button press
                  },
                  child: Text('Cash out'),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payout activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle see all button press
                    },
                    child: Text(
                      'See all',
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _buildPayoutItem(
                amount: '\$235.67',
                date: 'Initiated Mar 4, 2024',
                type: 'Weekly payment',
              ),
              SizedBox(height: 16),
              _buildPayoutItem(
                amount: '\$252.86',
                date: 'Initiated Feb 26, 2024',
                type: 'Weekly payment',
              ),
              SizedBox(height: 24),
              Text(
                'Payment Methods',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Help', style: TextStyle(fontSize: 16, color: Colors.blue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutItem({
    required String amount,
    required String date,
    required String type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          amount,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(date, style: TextStyle(fontSize: 14, color: Colors.grey)),
        SizedBox(height: 4),
        Text(type, style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
