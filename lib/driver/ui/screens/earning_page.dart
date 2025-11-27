import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../common/models/earnings_data.dart';
import '../../../common/services/earnings_service.dart';
import '../../../common/services/auth_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final EarningsService _earningsService = EarningsService();

  int? _driverId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverId();
  }

  Future<void> _loadDriverId() async {
    try {
      final driverId = await AuthService.getDriverId();

      setState(() {
        _driverId = driverId;
        _isLoading = false;
      });

      if (driverId == null) {
        debugPrint('⚠️ No driver profile found for current user');
      }
    } catch (e) {
      debugPrint('❌ Error loading driver ID: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Earnings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_driverId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Earnings')),
        body: const Center(child: Text('Driver profile not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: FutureBuilder<EarningsData?>(
        future: _earningsService.getCurrentWeekEarnings(_driverId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading earnings: ${snapshot.error}'),
            );
          }

          final earnings = snapshot.data;
          if (earnings == null) {
            return const Center(child: Text('No earnings data available'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range
                  Text(
                    _formatDateRange(earnings.periodStart, earnings.periodEnd),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),

                  // Total balance
                  Text(
                    earnings.formattedTotalBalance,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Week days (placeholder for now)
                  const Row(
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
                  const SizedBox(height: 16),

                  // Stats: Online time, Trips, Points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatColumn('Online', earnings.formattedOnlineTime),
                      _buildStatColumn('Trips', '${earnings.totalTrips}'),
                      _buildStatColumn('Points', '${earnings.points}'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // See details button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to detailed earnings page
                      },
                      child: const Text(
                        'See details',
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Payment method breakdowns
                  _buildPaymentBreakdown(earnings),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPaymentBreakdown(EarningsData earnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cash earnings section
        if (earnings.hasCashEarnings) ...[
          _buildPaymentSection(
            title: 'Cash Earnings',
            amount: earnings.formattedCashEarnings,
            subtitle: 'Available for immediate withdrawal',
            icon: Icons.money,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
        ],

        // Bank transfer earnings section
        if (earnings.hasBankTransferEarnings) ...[
          _buildPaymentSection(
            title: 'Bank Transfer Earnings',
            amount: earnings.formattedBankTransferEarnings,
            subtitle:
                earnings.nextPayoutDate != null
                    ? 'Payment scheduled for ${DateFormat('MMM d').format(earnings.nextPayoutDate!)}'
                    : 'No payment scheduled',
            icon: Icons.account_balance,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
        ],

        // Other payment methods section
        if (earnings.hasOtherEarnings) ...[
          _buildPaymentSection(
            title: 'Other Payment Methods',
            amount: earnings.formattedOtherEarnings,
            subtitle: 'Earnings from other payment methods',
            icon: Icons.payment,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
        ],

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    earnings.hasCashEarnings
                        ? () {
                          // TODO: Handle cash out
                        }
                        : null,
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('Cash out'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to summary page
                },
                icon: const Icon(Icons.summarize),
                label: const Text('Summary'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentSection({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
