import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/car_expense.dart';
import '../../services/car_expense_service.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/services/earnings_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CarExpenseCalculatorScreen extends StatefulWidget {
  const CarExpenseCalculatorScreen({super.key});

  @override
  State<CarExpenseCalculatorScreen> createState() =>
      _CarExpenseCalculatorScreenState();
}

class _CarExpenseCalculatorScreenState extends State<CarExpenseCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final CarExpenseService _expenseService = CarExpenseService();
  final EarningsService _earningsService = EarningsService();

  late TabController _tabController;
  int? _driverId;
  bool _isLoading = true;
  List<CarExpense> _expenses = [];
  DateTime _selectedMonth = DateTime.now();

  // Fuel calculator fields
  final TextEditingController _fuelPriceController = TextEditingController();
  double _totalDistanceTraveled = 0.0;
  double? _vehicleAverageConsumption; // L/100km from vehicle's car brand
  String _vehicleDisplayName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDriverData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fuelPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData() async {
    try {
      final driverId = await AuthService.getDriverId();
      if (driverId == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _driverId = driverId);
      await _loadExpenses();
    } catch (e) {
      print('❌ Error loading driver data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExpenses() async {
    if (_driverId == null) return;

    try {
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      );

      final expenses = await _expenseService.getExpensesByDateRange(
        _driverId!,
        startDate,
        endDate,
      );

      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
      await _loadTotalDistance();
      await _loadVehicleData();
    } catch (e) {
      print('❌ Error loading expenses: $e');
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
        1,
      );
      _isLoading = true;
    });
    _loadExpenses();
  }

  Future<void> _loadTotalDistance() async {
    if (_driverId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('ride_details')
          .select('distance')
          .eq('driver_id', _driverId!);

      final totalDistance = (response as List).fold<double>(
        0.0,
        (sum, record) =>
            sum + ((record['distance'] as num?)?.toDouble() ?? 0.0),
      );

      setState(() {
        _totalDistanceTraveled = totalDistance;
      });
    } catch (e) {
      print('❌ Error loading total distance: $e');
    }
  }

  Future<void> _loadVehicleData() async {
    if (_driverId == null) return;

    try {
      final response =
          await Supabase.instance.client
              .from('vehicles')
              .select('*, car_brands(*)')
              .eq('driver_id', _driverId!)
              .eq('status', true)
              .maybeSingle();

      if (response != null && response['car_brands'] != null) {
        final carBrand = response['car_brands'];
        setState(() {
          _vehicleAverageConsumption =
              (carBrand['average_consumption'] as num?)?.toDouble();
          _vehicleDisplayName = '${carBrand['company']} ${carBrand['model']}';
        });
      } else {
        setState(() {
          _vehicleDisplayName = 'No vehicle registered';
        });
      }
    } catch (e) {
      print('❌ Error loading vehicle data: $e');
      setState(() {
        _vehicleDisplayName = 'Error loading vehicle';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Car Expense Calculator')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_driverId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Car Expense Calculator')),
        body: const Center(child: Text('Driver profile not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Expense Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Reset All Expenses',
            onPressed: _showResetConfirmationDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.local_gas_station), text: 'Fuel'),
            Tab(icon: Icon(Icons.list), text: 'Expenses'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Summary'),
            Tab(icon: Icon(Icons.trending_up), text: 'Profit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFuelCalculatorTab(),
          _buildExpensesTab(),
          _buildSummaryTab(),
          _buildProfitAnalysisTab(),
        ],
      ),
      floatingActionButton:
          _tabController.index == 1
              ? FloatingActionButton(
                onPressed: _showAddExpenseDialog,
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  // ==================== FUEL CALCULATOR TAB ====================
  Widget _buildFuelCalculatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⛽ Fuel Consumption Calculator',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Display vehicle information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your Vehicle',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _vehicleDisplayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_vehicleAverageConsumption != null)
                                Text(
                                  'Avg: ${_vehicleAverageConsumption!.toStringAsFixed(2)} L/100km',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Fuel price input
                  TextField(
                    controller: _fuelPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fuel Price per Liter (\$)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      helperText: 'Enter current fuel price',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display total distance from completed rides (read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.route, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Distance Traveled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_totalDistanceTraveled.toStringAsFixed(2)} km',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _calculateFuelMetrics,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Calculate',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildFuelStatistics(),
        ],
      ),
    );
  }

  Widget _buildFuelStatistics() {
    final fuelExpenses =
        _expenses.where((e) => e.expenseType == 'fuel').toList();

    if (fuelExpenses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No fuel expenses recorded yet',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final totalFuelCost = fuelExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalLiters = fuelExpenses.fold(
      0.0,
      (sum, e) => sum + (e.fuelLiters ?? 0.0),
    );
    final totalDistance = fuelExpenses.fold(
      0.0,
      (sum, e) => sum + (e.distanceKm ?? 0.0),
    );

    final avgConsumption =
        totalDistance > 0 ? (totalLiters / totalDistance) * 100 : 0.0;
    final avgCostPerKm =
        totalDistance > 0 ? totalFuelCost / totalDistance : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Fuel Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Total Fuel Cost',
              '\$${totalFuelCost.toStringAsFixed(2)}',
            ),
            _buildStatRow(
              'Total Liters',
              '${totalLiters.toStringAsFixed(1)} L',
            ),
            _buildStatRow(
              'Total Distance',
              '${totalDistance.toStringAsFixed(0)} km',
            ),
            _buildStatRow(
              'Avg Consumption',
              '${avgConsumption.toStringAsFixed(2)} L/100km',
            ),
            _buildStatRow(
              'Cost per km',
              '\$${avgCostPerKm.toStringAsFixed(3)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _calculateFuelMetrics() {
    final fuelPrice = double.tryParse(_fuelPriceController.text);
    final distance = _totalDistanceTraveled;
    final avgConsumption = _vehicleAverageConsumption;

    if (fuelPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter fuel price per liter')),
      );
      return;
    }

    if (distance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No distance data available. Complete some rides first.',
          ),
        ),
      );
      return;
    }

    if (avgConsumption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vehicle average consumption not available. Please update your vehicle information.',
          ),
        ),
      );
      return;
    }

    // Calculate fuel consumption automatically
    final liters = (distance * avgConsumption) / 100;
    final cost = liters * fuelPrice;
    final consumption = avgConsumption; // Already in L/100km
    final costPerKm = cost / distance;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Fuel Metrics'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consumption: ${consumption.toStringAsFixed(2)} L/100km'),
                const SizedBox(height: 8),
                Text('Cost per km: \$${costPerKm.toStringAsFixed(3)}'),
                const SizedBox(height: 16),
                const Text(
                  'Would you like to save this as an expense?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveFuelExpense(liters, cost, distance);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveFuelExpense(
    double liters,
    double cost,
    double distance,
  ) async {
    try {
      final expense = CarExpense(
        driverId: _driverId!,
        expenseType: 'fuel',
        amount: cost,
        description: 'Fuel refill - ${liters.toStringAsFixed(1)}L',
        expenseDate: DateTime.now(),
        fuelLiters: liters,
        distanceKm: distance,
      );

      await _expenseService.addExpense(expense);
      await _loadExpenses();

      _fuelPriceController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel expense saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving expense: $e')));
      }
    }
  }

  // ==================== EXPENSES TAB ====================
  Widget _buildExpensesTab() {
    return Column(
      children: [
        _buildMonthSelector(),
        Expanded(
          child:
              _expenses.isEmpty
                  ? const Center(
                    child: Text(
                      'No expenses recorded for this month',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                  : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      return _buildExpenseCard(_expenses[index]);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(CarExpense expense) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            expense.expenseTypeIcon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          expense.expenseTypeDisplayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.description != null) Text(expense.description!),
            Text(
              expense.formattedDate,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (expense.fuelConsumption != null)
              Text(
                '${expense.fuelConsumption!.toStringAsFixed(2)} L/100km',
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              expense.formattedAmount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (expense.costPerKm != null)
              Text(
                '\$${expense.costPerKm!.toStringAsFixed(3)}/km',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        onLongPress: () => _showExpenseOptions(expense),
      ),
    );
  }

  void _showExpenseOptions(CarExpense expense) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditExpenseDialog(expense);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteExpense(expense);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _deleteExpense(CarExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Expense'),
            content: const Text(
              'Are you sure you want to delete this expense?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true && expense.id != null) {
      try {
        await _expenseService.deleteExpense(expense.id!);
        await _loadExpenses();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Expense deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting expense: $e')));
        }
      }
    }
  }

  // ==================== SUMMARY TAB ====================
  Widget _buildSummaryTab() {
    final breakdown = <String, double>{};
    for (var expense in _expenses) {
      breakdown[expense.expenseType] =
          (breakdown[expense.expenseType] ?? 0.0) + expense.amount;
    }

    final total = _expenses.fold(0.0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Total Expenses',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (breakdown.isNotEmpty) _buildPieChart(breakdown),
          const SizedBox(height: 16),
          ...breakdown.entries.map((entry) {
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    CarExpense(
                      driverId: 0,
                      expenseType: entry.key,
                      amount: 0,
                      expenseDate: DateTime.now(),
                    ).expenseTypeIcon,
                  ),
                ),
                title: Text(
                  CarExpense(
                    driverId: 0,
                    expenseType: entry.key,
                    amount: 0,
                    expenseDate: DateTime.now(),
                  ).expenseTypeDisplayName,
                ),
                subtitle: Text('${percentage.toStringAsFixed(1)}%'),
                trailing: Text(
                  '\$${entry.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> breakdown) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    final sections =
        breakdown.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          final total = breakdown.values.fold(0.0, (sum, val) => sum + val);
          final percentage = (data.value / total) * 100;

          return PieChartSectionData(
            value: data.value,
            title: '${percentage.toStringAsFixed(0)}%',
            color: colors[index % colors.length],
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== PROFIT ANALYSIS TAB ====================
  Widget _buildProfitAnalysisTab() {
    return FutureBuilder(
      future: _loadProfitData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('No data available'));
        }

        final earnings = data['earnings'] ?? 0.0;
        final expenses = data['expenses'] ?? 0.0;
        final profit = earnings - expenses;
        final profitMargin = earnings > 0 ? (profit / earnings) * 100 : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMonthSelector(),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        profit >= 0 ? 'Net Profit' : 'Net Loss',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${profit.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Profit Margin: ${profitMargin.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatRow(
                        'Total Earnings',
                        '\$${earnings.toStringAsFixed(2)}',
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Total Expenses',
                        '\$${expenses.toStringAsFixed(2)}',
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Net ${profit >= 0 ? "Profit" : "Loss"}',
                        '\$${profit.abs().toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildProfitTips(profitMargin),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, double>> _loadProfitData() async {
    if (_driverId == null) return {'earnings': 0.0, 'expenses': 0.0};

    try {
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        0,
      );

      final earningsData = await _earningsService.getEarningsForPeriod(
        _driverId!,
        startDate,
        endDate,
      );
      final expenses = await _expenseService.getTotalExpenses(
        _driverId!,
        startDate,
        endDate,
      );

      return {
        'earnings': earningsData?.totalEarnings ?? 0.0,
        'expenses': expenses,
      };
    } catch (e) {
      print('❌ Error loading profit data: $e');
      return {'earnings': 0.0, 'expenses': 0.0};
    }
  }

  Widget _buildProfitTips(double profitMargin) {
    String tip;
    IconData icon;
    Color color;

    if (profitMargin >= 30) {
      tip = 'Excellent! Your profit margin is healthy. Keep up the good work!';
      icon = Icons.thumb_up;
      color = Colors.green;
    } else if (profitMargin >= 15) {
      tip =
          'Good profit margin. Consider tracking fuel efficiency to improve further.';
      icon = Icons.trending_up;
      color = Colors.blue;
    } else if (profitMargin >= 0) {
      tip =
          'Low profit margin. Review your expenses and consider optimizing routes.';
      icon = Icons.warning;
      color = Colors.orange;
    } else {
      tip =
          'You\'re operating at a loss. Review all expenses and consider increasing work hours.';
      icon = Icons.error;
      color = Colors.red;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(tip, style: TextStyle(color: color.withOpacity(0.8))),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ADD/EDIT EXPENSE DIALOGS ====================
  void _showAddExpenseDialog() {
    _showExpenseDialog(null);
  }

  void _showEditExpenseDialog(CarExpense expense) {
    _showExpenseDialog(expense);
  }

  void _showExpenseDialog(CarExpense? expense) {
    final isEdit = expense != null;
    String selectedType = expense?.expenseType ?? 'fuel';
    final amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    DateTime selectedDate = expense?.expenseDate ?? DateTime.now();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Expense Type',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'fuel',
                              child: Text('⛽ Fuel'),
                            ),
                            DropdownMenuItem(
                              value: 'maintenance',
                              child: Text('🔧 Maintenance'),
                            ),
                            DropdownMenuItem(
                              value: 'insurance',
                              child: Text('🛡️ Insurance'),
                            ),
                            DropdownMenuItem(
                              value: 'registration',
                              child: Text('📋 Registration'),
                            ),
                            DropdownMenuItem(
                              value: 'depreciation',
                              child: Text('📉 Depreciation'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('💰 Other'),
                            ),
                          ],
                          onChanged: (value) {
                            setDialogState(() => selectedType = value!);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Amount (\$)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Date'),
                          subtitle: Text(
                            DateFormat('MMM d, yyyy').format(selectedDate),
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setDialogState(() => selectedDate = date);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount'),
                            ),
                          );
                          return;
                        }

                        final newExpense = CarExpense(
                          id: expense?.id,
                          driverId: _driverId!,
                          expenseType: selectedType,
                          amount: amount,
                          description:
                              descriptionController.text.isEmpty
                                  ? null
                                  : descriptionController.text,
                          expenseDate: selectedDate,
                        );

                        try {
                          if (isEdit) {
                            await _expenseService.updateExpense(newExpense);
                          } else {
                            await _expenseService.addExpense(newExpense);
                          }

                          await _loadExpenses();
                          Navigator.pop(context);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Expense updated successfully'
                                      : 'Expense added successfully',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      child: Text(isEdit ? 'Update' : 'Add'),
                    ),
                  ],
                ),
          ),
    );
  }

  // ==================== RESET FUNCTIONALITY ====================
  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => _ResetConfirmationDialog(onConfirm: _resetAllExpenses),
    );
  }

  Future<void> _resetAllExpenses() async {
    if (_driverId == null) return;

    try {
      await _expenseService.resetAllExpenses(_driverId!);
      await _loadExpenses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All expenses have been reset'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting expenses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ==================== RESET CONFIRMATION DIALOG ====================
class _ResetConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const _ResetConfirmationDialog({required this.onConfirm});

  @override
  State<_ResetConfirmationDialog> createState() =>
      _ResetConfirmationDialogState();
}

class _ResetConfirmationDialogState extends State<_ResetConfirmationDialog> {
  int _countdown = 5;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() => _countdown--);
        _startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 28),
          SizedBox(width: 8),
          Text('Reset All Expenses?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will permanently delete ALL car expense records.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This action cannot be undone!',
            style: TextStyle(color: Colors.red),
          ),
          if (_countdown > 0) const SizedBox(height: 16),
          if (_countdown > 0)
            Center(
              child: Text(
                'Please wait $_countdown second${_countdown != 1 ? 's' : ''}...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _countdown == 0 && !_isDeleting ? _handleDelete : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.grey,
          ),
          child:
              _isDeleting
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Delete All'),
        ),
      ],
    );
  }

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    Navigator.pop(context);
    widget.onConfirm();
  }
}
