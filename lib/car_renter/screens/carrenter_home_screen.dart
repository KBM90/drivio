import 'package:drivio_app/car_renter/models/car_renter.dart';
import 'package:drivio_app/car_renter/screens/car_renter_profile_screen.dart';
import 'package:drivio_app/car_renter/services/car_rental_service.dart';
import 'package:drivio_app/common/models/car_brand.dart';
import 'package:drivio_app/common/models/car_rental_request.dart';
import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/common/providers/notification_provider.dart';
import 'package:drivio_app/common/screens/services_page.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Widget _getCurrentScreen() {
    switch (_currentBottomNavIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return CarRenterProfileScreen(carRenter: _carRenter!);
      case 2:
        return const ServicesPage(showBackButton: false);
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_carRenter!.businessName ?? 'Car Rental Dashboard'),
        actions: [
          // Notification Icon with Badge
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // Navigate to notifications screen (to be implemented)
                      // For now just show a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'You have ${notifProvider.unreadCount} unread notifications',
                          ),
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
        bottom: TabBar(
          controller: _dashboardTabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Requests'),
            Tab(icon: Icon(Icons.directions_car), text: 'My Cars'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _dashboardTabController,
        children: [
          _RentalRequestsTab(renterId: _carRenter!.id, service: _service),
          _MyCarsTab(renterId: _carRenter!.id, service: _service),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_carRenter == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to load car renter profile'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => AuthService.signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
        ],
        selectedItemColor: Colors.blue,
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

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final requests = await widget.service.getRentalRequestsForRenter(
      widget.renterId,
    );
    if (mounted) {
      setState(() {
        _requests = requests;
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
                          'No requests found',
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
                    color: Colors.blue,
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
                      label: const Text('Reject'),
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
                      label: const Text('Approve'),
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

  void _showAddCarDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _CarFormDialog(
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
          (context) => _CarFormDialog(
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cars.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.car_rental, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No cars added yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to add your first car',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadCars,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cars.length,
                  itemBuilder: (context, index) {
                    return _CarCard(
                      car: _cars[index],
                      onEdit: () => _showEditCarDialog(_cars[index]),
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Car'),
                                content: const Text(
                                  'Are you sure you want to delete this car?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );

                        if (confirm == true) {
                          await widget.service.deleteCarRental(_cars[index].id);
                          _loadCars();
                        }
                      },
                      onToggleAvailability: () async {
                        if (_cars[index].isAvailable) {
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
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
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
                              carId: _cars[index].id,
                              isAvailable: false,
                              unavailableFrom: dateRange.start,
                              unavailableUntil: dateRange.end,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
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
                            carId: _cars[index].id,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCarDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Car'),
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
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
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
                      color: Colors.blue,
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
                      child: const Text(
                        'Available',
                        style: TextStyle(
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
                          const Text(
                            'Unavailable',
                            style: TextStyle(
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

// Car Form Dialog
class _CarFormDialog extends StatefulWidget {
  final int renterId;
  final CarRentalService service;
  final ProvidedCarRental? car;
  final VoidCallback onSaved;

  const _CarFormDialog({
    required this.renterId,
    required this.service,
    this.car,
    required this.onSaved,
  });

  @override
  State<_CarFormDialog> createState() => _CarFormDialogState();
}

class _CarFormDialogState extends State<_CarFormDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCarBrandId;
  CarBrand? _selectedCarBrand;
  List<CarBrand> _carBrands = [];
  bool _loadingBrands = true;
  late TextEditingController _carBrandController;
  late TextEditingController _yearController;
  late TextEditingController _colorController;
  late TextEditingController _cityController;
  late TextEditingController _priceController;
  late TextEditingController _plateController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCarBrandId = widget.car?.carBrandId;
    _carBrandController = TextEditingController();
    _yearController = TextEditingController(text: widget.car?.year?.toString());
    _colorController = TextEditingController(text: widget.car?.color);
    _cityController = TextEditingController(text: widget.car?.city);
    _priceController = TextEditingController(
      text: widget.car?.dailyPrice.toString(),
    );
    _plateController = TextEditingController(text: widget.car?.plateNumber);
    _loadCarBrands();
  }

  Future<void> _loadCarBrands() async {
    final brands = await widget.service.getCarBrands();
    if (mounted) {
      setState(() {
        _carBrands = brands;
        _loadingBrands = false;

        // Set initial value if editing existing car
        if (widget.car?.carBrandId != null) {
          _selectedCarBrand = _carBrands.firstWhere(
            (b) => b.id == widget.car!.carBrandId,
            orElse: () => _carBrands.first,
          );
          _carBrandController.text =
              '${_selectedCarBrand!.company} ${_selectedCarBrand!.model}';
        }
      });
    }
  }

  @override
  void dispose() {
    _carBrandController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _cityController.dispose();
    _priceController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCarBrandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car brand')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.car == null) {
        // Add new car
        await widget.service.addCarRental(
          carRenterId: widget.renterId,
          carBrandId: _selectedCarBrandId!,
          year: int.parse(_yearController.text.trim()),
          color: _colorController.text.trim(),
          city: _cityController.text.trim(),
          dailyPrice: double.parse(_priceController.text.trim()),
          plateNumber:
              _plateController.text.trim().isEmpty
                  ? null
                  : _plateController.text.trim(),
        );
      } else {
        // Update existing car
        await widget.service.updateCarRental(
          carId: widget.car!.id,
          carBrandId: _selectedCarBrandId,
          year: int.parse(_yearController.text.trim()),
          color: _colorController.text.trim(),
          city: _cityController.text.trim(),
          dailyPrice: double.parse(_priceController.text.trim()),
          plateNumber:
              _plateController.text.trim().isEmpty
                  ? null
                  : _plateController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.car == null ? 'Add Car' : 'Edit Car'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loadingBrands)
                const Center(child: CircularProgressIndicator())
              else
                Autocomplete<CarBrand>(
                  initialValue:
                      _carBrandController.text.isNotEmpty
                          ? TextEditingValue(text: _carBrandController.text)
                          : null,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return _carBrands;
                    }
                    return _carBrands.where((CarBrand brand) {
                      final searchText = textEditingValue.text.toLowerCase();
                      final brandText =
                          '${brand.company} ${brand.model}'.toLowerCase();
                      return brandText.contains(searchText);
                    });
                  },
                  displayStringForOption:
                      (CarBrand brand) => '${brand.company} ${brand.model}',
                  onSelected: (CarBrand brand) {
                    setState(() {
                      _selectedCarBrand = brand;
                      _selectedCarBrandId = brand.id;
                    });
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    // Sync with our controller
                    if (_carBrandController.text.isNotEmpty &&
                        textEditingController.text.isEmpty) {
                      textEditingController.text = _carBrandController.text;
                    }

                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Car Brand & Model *',
                        hintText: 'Search for a car brand...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      validator: (v) {
                        if (v?.trim().isEmpty ?? true) {
                          return 'Please select a car brand';
                        }
                        if (_selectedCarBrandId == null) {
                          return 'Please select a valid car brand from the list';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Clear selection if user modifies the text
                        if (_selectedCarBrand != null) {
                          final expectedText =
                              '${_selectedCarBrand!.company} ${_selectedCarBrand!.model}';
                          if (value != expectedText) {
                            setState(() {
                              _selectedCarBrandId = null;
                              _selectedCarBrand = null;
                            });
                          }
                        }
                      },
                    );
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year *'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  final year = int.tryParse(v!);
                  if (year == null || year < 1900 || year > 2030) {
                    return 'Invalid year';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(labelText: 'Color *'),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City *'),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Daily Price (MAD) *',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.trim().isEmpty ?? true) return 'Required';
                  final price = double.tryParse(v!);
                  if (price == null || price <= 0) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _plateController,
                decoration: const InputDecoration(
                  labelText: 'Plate Number (Optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.car == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
