import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../common/models/earnings_data.dart';
import '../../../common/models/trip_detail.dart';
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
  DateTime? _selectedDay;
  EarningsData? _selectedDayEarnings;
  bool _showDetails = false;
  List<TripDetail> _tripDetails = [];
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadDriverId();
  }

  Future<void> _loadDriverId() async {
    try {
      final driverId = await AuthService.getDriverId();

      if (driverId == null) {
        debugPrint('⚠️ No driver profile found for current user');
        setState(() => _isLoading = false);
        return;
      }

      // Select current day by default
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      setState(() {
        _driverId = driverId;
        _selectedDay = today;
        _isLoading = false;
      });

      // Load today's earnings
      _loadDayEarnings(today);
    } catch (e) {
      debugPrint('❌ Error loading driver ID: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDayEarnings(DateTime day) async {
    if (_driverId == null) return;

    try {
      final earnings = await _earningsService.getDailyEarnings(_driverId!, day);
      setState(() {
        _selectedDayEarnings = earnings;
      });
    } catch (e) {
      debugPrint('❌ Error loading day earnings: $e');
    }
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
      _selectedDayEarnings = null; // Show loading state
      _showDetails = false; // Collapse details when changing days
      _tripDetails = [];
    });
    _loadDayEarnings(day);
  }

  Future<void> _toggleDetails() async {
    if (_driverId == null || _selectedDay == null) return;

    setState(() {
      _showDetails = !_showDetails;
    });

    // Load trip details if expanding and not already loaded
    if (_showDetails && _tripDetails.isEmpty) {
      setState(() => _isLoadingDetails = true);

      final details = await _earningsService.getDailyTripDetails(
        _driverId!,
        _selectedDay!,
      );

      setState(() {
        _tripDetails = details;
        _isLoadingDetails = false;
      });
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

                  // Interactive week days
                  _buildWeekDaysSelector(earnings.periodStart),
                  const SizedBox(height: 16),

                  // Stats: Online time, Trips, Points (for selected day or week)
                  _selectedDayEarnings == null
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatColumn(
                            'Earnings',
                            _selectedDayEarnings!.formattedTotalBalance,
                          ),
                          _buildStatColumn(
                            'Online',
                            _selectedDayEarnings!.formattedOnlineTime,
                          ),
                          _buildStatColumn(
                            'Trips',
                            '${_selectedDayEarnings!.totalTrips}',
                          ),
                          _buildStatColumn(
                            'Points',
                            '${_selectedDayEarnings!.points}',
                          ),
                        ],
                      ),
                  const SizedBox(height: 24),

                  // See details button with expandable section
                  Column(
                    children: [
                      Center(
                        child: TextButton.icon(
                          onPressed: _toggleDetails,
                          icon: Icon(
                            _showDetails
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                          label: Text(
                            _showDetails ? 'Hide details' : 'See details',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child:
                            _showDetails
                                ? _buildDetailsSection()
                                : const SizedBox.shrink(),
                      ),
                    ],
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

  Widget _buildWeekDaysSelector(DateTime weekStart) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = weekStart.add(Duration(days: index));
        final dayNormalized = DateTime(day.year, day.month, day.day);
        final isSelected =
            _selectedDay != null &&
            dayNormalized.year == _selectedDay!.year &&
            dayNormalized.month == _selectedDay!.month &&
            dayNormalized.day == _selectedDay!.day;
        final isToday =
            dayNormalized.year == today.year &&
            dayNormalized.month == today.month &&
            dayNormalized.day == today.day;

        return GestureDetector(
          onTap: () => _onDaySelected(dayNormalized),
          child: Container(
            width: 40,
            height: 60,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border:
                  isToday
                      ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      )
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayLabels[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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

  Widget _buildDetailsSection() {
    if (_isLoadingDetails) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tripDetails.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'No trips found for this day',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildDailySummary(),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Trips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tripDetails.length,
          itemBuilder: (context, index) {
            return _buildTripCard(_tripDetails[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTripCard(TripDetail trip) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip.formattedTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        trip.status == 'completed'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trip.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          trip.status == 'completed'
                              ? Colors.green
                              : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  trip.formattedDistance,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.payment, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  trip.paymentMethodName,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fare',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      trip.formattedPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commission',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '- ${trip.formattedCommission}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You earned',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      trip.formattedDriverEarnings,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary() {
    final totalEarnings = _tripDetails.fold<double>(
      0,
      (sum, trip) => sum + trip.driverEarnings,
    );
    final totalCommission = _tripDetails.fold<double>(
      0,
      (sum, trip) => sum + trip.commissionAmount,
    );
    final totalFare = _tripDetails.fold<double>(
      0,
      (sum, trip) => sum + trip.price,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Trips', '${_tripDetails.length}'),
              _buildSummaryItem(
                'Total Fare',
                '\$${totalFare.toStringAsFixed(2)}',
              ),
              _buildSummaryItem(
                'Commission',
                '\$${totalCommission.toStringAsFixed(2)}',
              ),
              _buildSummaryItem(
                'Net Earnings',
                '\$${totalEarnings.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
