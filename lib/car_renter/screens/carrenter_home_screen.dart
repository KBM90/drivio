import 'package:drivio_app/car_renter/models/car_renter.dart';
import 'package:drivio_app/car_renter/screens/car_renter_settings_screen.dart';
import 'package:drivio_app/car_renter/services/car_rental_service.dart';
import 'package:drivio_app/common/models/car_brand.dart';
import 'package:drivio_app/common/models/car_rental_request.dart';
import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/common/providers/notification_provider.dart';
import 'package:drivio_app/common/screens/services_page.dart';
import 'package:drivio_app/common/screens/notifications_screen.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/common/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:drivio_app/common/constants/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drivio_app/car_renter/widgets/car_form_dialog.dart';

class CarRenterHomeScreen extends StatefulWidget {
  const CarRenterHomeScreen({super.key});

  @override
  State<CarRenterHomeScreen> createState() => _CarRenterHomeScreenState();
}

class _CarRenterHomeScreenState extends State<CarRenterHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _dashboardTabController;
  final CarRentalService _service = CarRentalService();
  CarRenter? _carRenter;
  bool _isLoading = true;
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardTabController = TabController(length: 2, vsync: this);
    _loadCarRenterData();
  }

  Future<void> _loadCarRenterData() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final response =
          await Supabase.instance.client
              .from('car_renters')
              .select('*')
              .eq('user_id', userId)
              .single();

      if (mounted) {
        setState(() {
          _carRenter = CarRenter.fromJson(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading car renter data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _dashboardTabController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
  }

  Widget _buildDashboardTab() {
    return TabBarView(
      controller: _dashboardTabController,
      children: [
        _RentalRequestsTab(renterId: _carRenter!.id, service: _service),
        _MyCarsTab(renterId: _carRenter!.id, service: _service),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_carRenter == null) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n?.error ?? 'Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n?.failedToLoadCarRenterProfile ?? 'Failed to load car renter profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AuthService.signOut(),
                child: Text(l10n?.logOut ?? 'Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    // Decide which screen content to show
    Widget body;
    switch (_currentBottomNavIndex) {
      case 0:
        body = _buildDashboardTab();
        break;
      case 1:
        body = const ServicesPage(showBackButton: false);
        break;
      case 2:
        body = CarRenterSettingsScreen(carRenter: _carRenter!);
        break;
      default:
        body = _buildDashboardTab();
    }

    // Only show the TabBar when on the Dashboard tab
    final PreferredSizeWidget? bottomAppBar =
        _currentBottomNavIndex == 0
            ? TabBar(
              controller: _dashboardTabController,
              tabs: [
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_car, color: Colors.white),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)?.requests ?? 'Requests',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.format_list_bulleted_add, color: Colors.white),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)?.myCars ?? 'My Cars',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
            : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/app/app_logo_without_background.png',
          height: 70,
        ),
        centerTitle: true,
        actions: [
          // Notification Icon with Badge
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        bottom: bottomAppBar,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.car_repair),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// Rental Requests Tab
class _RentalRequestsTab extends StatefulWidget {
  final int renterId;
  final CarRentalService service;

  const _RentalRequestsTab({required this.renterId, required this.service});

  @override
  State<_RentalRequestsTab> createState() => _RentalRequestsTabState();
}

class _RentalRequestsTabState extends State<_RentalRequestsTab> {
  List<CarRentalRequest> _requests = [];
  bool _isLoading = true;
  String _filter = 'all';
  int _availableCarsCount = 0;
  double _revenueThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final requestsFuture = widget.service.getRentalRequestsForRenter(
      widget.renterId,
    );
    final availableCarsFuture = widget.service.getAvailableCarsByRenterId(
      widget.renterId,
    );

    final requests = await requestsFuture;
    final availableCars = await availableCarsFuture;

    // Calculate revenue for the current month (confirmed/active/completed)
    final now = DateTime.now();
    double monthlyRevenue = 0;
    for (final r in requests) {
      final date = r.startDate;
      final isThisMonth =
          date.year == now.year && date.month == now.month;
      final isRevenueStatus =
          r.status == 'confirmed' ||
          r.status == 'active' ||
          r.status == 'completed';
      if (isThisMonth && isRevenueStatus) {
        monthlyRevenue += (r.totalPrice ?? 0);
      }
    }

    if (mounted) {
      setState(() {
        _requests = requests;
        _availableCarsCount = availableCars.length;
        _revenueThisMonth = monthlyRevenue;
        _isLoading = false;
      });
    }
  }

  List<CarRentalRequest> get _filteredRequests {
    if (_filter == 'all') return _requests;
    return _requests.where((r) => r.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              _FilterChip('All', 'all'),
              _FilterChip('Pending', 'pending'),
              _FilterChip('Confirmed', 'confirmed'),
              _FilterChip('Cancelled', 'cancelled'),
              _FilterChip('Active', 'active'),
              _FilterChip('Completed', 'completed'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryStatCard(
                      title: AppLocalizations.of(context)?.totalRequests ?? 'Total Requests',
                      primaryValue: _requests.length.toString(),
                      icon: Icons.receipt_long,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryStatCard(
                      title: AppLocalizations.of(context)?.activeRentals ?? 'Active Rentals',
                      primaryValue: _requests
                          .where((r) => r.status == 'active')
                          .length
                          .toString(),
                      icon: Icons.play_circle_fill,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStatCard(
                      title: AppLocalizations.of(context)?.availableCars ?? 'Available Cars',
                      primaryValue: _availableCarsCount.toString(),
                      icon: Icons.directions_car_filled,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryStatCard(
                      title: AppLocalizations.of(context)?.revenueThisMonth ?? 'Revenue This Month',
                      primaryValue:
                          '${_revenueThisMonth.toStringAsFixed(0)} MAD',
                      icon: Icons.attach_money,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRequests.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)?.noRequestsFound ?? 'No requests found',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _loadRequests,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredRequests.length,
                      itemBuilder: (context, index) {
                        return _RequestCard(
                          request: _filteredRequests[index],
                          onStatusChanged: _loadRequests,
                          service: widget.service,
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _FilterChip(String label, String value) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filter = value);
        },
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String title;
  final String primaryValue;
  final IconData icon;
  final Color color;
  final String? secondaryLabel;
  final String? secondaryValue;

  const _SummaryStatCard({
    required this.title,
    required this.primaryValue,
    required this.icon,
    required this.color,
    this.secondaryLabel,
    this.secondaryValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              primaryValue,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (secondaryLabel != null && secondaryValue != null)
              Text(
                '$secondaryLabel: $secondaryValue',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CarRentalRequest request;
  final VoidCallback onStatusChanged;
  final CarRentalService service;

  const _RequestCard({
    required this.request,
    required this.onStatusChanged,
    required this.service,
  });

  Color _getStatusColor() {
    switch (request.status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.carRental?.displayName ?? 'Car',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(request.startDate)} - ${dateFormat.format(request.endDate)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${request.totalDays ?? 0} days',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(width: 24),
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${request.totalPrice?.toStringAsFixed(0) ?? 0} MAD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            if (request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await service.updateRequestStatus(
                          requestId: request.id,
                          status: 'cancelled',
                        );
                        onStatusChanged();
                      },
                      icon: const Icon(Icons.close),
                      label: Text(AppLocalizations.of(context)?.reject ?? 'Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await service.updateRequestStatus(
                          requestId: request.id,
                          status: 'confirmed',
                        );
                        onStatusChanged();
                      },
                      icon: const Icon(Icons.check),
                      label: Text(AppLocalizations.of(context)?.approve ?? 'Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// My Cars Tab
class _MyCarsTab extends StatefulWidget {
  final int renterId;
  final CarRentalService service;

  const _MyCarsTab({required this.renterId, required this.service});

  @override
  State<_MyCarsTab> createState() => _MyCarsTabState();
}

class _MyCarsTabState extends State<_MyCarsTab> {
  List<ProvidedCarRental> _cars = [];
  bool _isLoading = true;
  String _availabilityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    setState(() => _isLoading = true);
    final cars = await widget.service.getCarsByRenterId(widget.renterId);
    if (mounted) {
      setState(() {
        _cars = cars;
        _isLoading = false;
      });
    }
  }

  List<ProvidedCarRental> get _filteredCars {
    switch (_availabilityFilter) {
      case 'available':
        return _cars.where((c) => c.isAvailable).toList();
      case 'unavailable':
        return _cars.where((c) => !c.isAvailable).toList();
      default:
        return _cars;
    }
  }

  Widget _availabilityFilterChip(String label, String value) {
    final isSelected = _availabilityFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _availabilityFilter = value);
        },
      ),
    );
  }

  void _showAddCarDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CarFormDialog(
            renterId: widget.renterId,
            service: widget.service,
            onSaved: _loadCars,
          ),
    );
  }

  void _showEditCarDialog(ProvidedCarRental car) {
    showDialog(
      context: context,
      builder:
          (context) => CarFormDialog(
            renterId: widget.renterId,
            service: widget.service,
            car: car,
            onSaved: _loadCars,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cars.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.car_rental,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)?.noCarsAddedYet ?? 'No cars added yet',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)?.tapToAddFirstCar ?? 'Tap + to add your first car',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          _availabilityFilterChip('All', 'all'),
                          _availabilityFilterChip(AppLocalizations.of(context)?.available ?? 'Available', 'available'),
                          _availabilityFilterChip(AppLocalizations.of(context)?.offline ?? 'Unavailable', 'unavailable'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCars,
                        child: _filteredCars.isEmpty
                            ? ListView(
                                padding: const EdgeInsets.all(32),
                                children: [
                                  Center(
                                    child: Text(
                                      AppLocalizations.of(context)?.noCarsMatchFilter ?? 'No cars match this filter',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredCars.length,
                                itemBuilder: (context, index) {
                                  final car = _filteredCars[index];
                                  return _CarCard(
                                    car: car,
                                    onEdit: () => _showEditCarDialog(car),
                                    onDelete: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(AppLocalizations.of(context)?.deleteCar ?? 'Delete Car'),
                                          content: Text(
                                            AppLocalizations.of(context)?.confirmDeleteCar ?? 'Are you sure you want to delete this car?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: Text(
                                                AppLocalizations.of(context)?.delete ?? 'Delete',
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await widget.service
                                            .deleteCarRental(car.id);
                                        _loadCars();
                                      }
                                    },
                                    onToggleAvailability: () async {
                                      if (car.isAvailable) {
                                        // Show date range picker when marking as unavailable
                                        final DateTimeRange? dateRange =
                                            await showDateRangePicker(
                                          context: context,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 365),
                                          ),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context)
                                                  .copyWith(
                                                colorScheme:
                                                    const ColorScheme.light(
                                                  primary: Colors.blue,
                                                  onPrimary: Colors.white,
                                                  surface: Colors.white,
                                                  onSurface: Colors.black,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );

                                        if (dateRange != null) {
                                          // Mark as unavailable with date range
                                          await widget.service.updateCarRental(
                                            carId: car.id,
                                            isAvailable: false,
                                            unavailableFrom: dateRange.start,
                                            unavailableUntil: dateRange.end,
                                          );

                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Car marked unavailable from ${DateFormat('MMM dd').format(dateRange.start)} to ${DateFormat('MMM dd, yyyy').format(dateRange.end)}',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }

                                          _loadCars();
                                        }
                                      } else {
                                        // Mark as available and clear dates
                                        await widget.service.updateCarRental(
                                          carId: car.id,
                                          isAvailable: true,
                                          unavailableFrom: null,
                                          unavailableUntil: null,
                                        );
                                        _loadCars();
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCarDialog,
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)?.add ?? 'Add Car'),
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  final ProvidedCarRental car;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const _CarCard({
    required this.car,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      car.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 20),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)?.edit ?? 'Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: Row(
                              children: [
                                Icon(
                                  car.isAvailable
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  car.isAvailable
                                      ? 'Mark Unavailable'
                                      : 'Mark Available',
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'toggle':
                          onToggleAvailability();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(car.city, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(width: 16),
                  if (car.color != null) ...[
                    Icon(Icons.palette, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(car.color!, style: TextStyle(color: Colors.grey[700])),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${car.dailyPrice.toStringAsFixed(0)} MAD/day',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (car.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.available ?? 'Available',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.offline ?? 'Unavailable',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (car.unavailableFrom != null &&
                              car.unavailableUntil != null)
                            Text(
                              '${DateFormat('MMM dd').format(car.unavailableFrom!)} - ${DateFormat('MMM dd').format(car.unavailableUntil!)}',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


