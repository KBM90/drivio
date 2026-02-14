import 'dart:async';
import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/car_renter/services/car_rental_service.dart';
import 'package:drivio_app/common/screens/car_renter_public_profile_screen.dart';
import 'package:drivio_app/common/helpers/osrm_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  final CarRentalService _carRentalService = CarRentalService();

  List<ProvidedCarRental> _cars = [];
  List<String> _cities = [];
  bool _isLoading = true;

  // Filters
  String? _selectedCity;
  double _maxPrice = 1000;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Load cities and cars
    final cities = await _carRentalService.getAvailableCities();
    await _loadCars();

    if (mounted) {
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCars() async {
    // For now, we'll load cars without user location
    // You can add location provider later if needed
    final cars = await _carRentalService.getAvailableCars(
      city: _selectedCity,
      maxPrice: _maxPrice,
      startDate: _startDate,
      endDate: _endDate,
      userLocation: null, // Can be enhanced with location provider
    );

    if (mounted) {
      setState(() {
        _cars = cars;
      });
    }
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => _FiltersBottomSheet(
            cities: _cities,
            selectedCity: _selectedCity,
            maxPrice: _maxPrice,
            startDate: _startDate,
            endDate: _endDate,
            onApply: (city, price, start, end) {
              setState(() {
                _selectedCity = city;
                _maxPrice = price;
                _startDate = start;
                _endDate = end;
              });
              _loadCars();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Rental'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersBottomSheet,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _cars.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  _buildFilterChips(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cars.length,
                      itemBuilder: (context, index) {
                        return _CarCard(car: _cars[index]);
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const _NewRentalRequestDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedCity != null)
            Chip(
              label: Text(_selectedCity!),
              onDeleted: () {
                setState(() => _selectedCity = null);
                _loadCars();
              },
            ),
          if (_startDate != null && _endDate != null)
            Chip(
              label: Text(
                '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}',
              ),
              onDeleted: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                _loadCars();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.car_rental, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No cars available',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  final ProvidedCarRental car;

  const _CarCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car image
          AspectRatio(
            aspectRatio: 16 / 9,
            child:
                car.images != null && car.images!.isNotEmpty
                    ? Image.network(
                      car.images!.first,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                    )
                    : _buildPlaceholderImage(),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Model and year
                Text(
                  car.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // City
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(car.city, style: TextStyle(color: Colors.grey[600])),
                    if (car.distance != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${car.distance!.toStringAsFixed(1)} km away',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                // Car renter info
                if (car.carRenter != null) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue[100],
                        backgroundImage:
                            car.carRenter!.user?.profileImagePath != null
                                ? NetworkImage(
                                  car.carRenter!.user!.profileImagePath!,
                                )
                                : null,
                        child:
                            car.carRenter!.user?.profileImagePath == null
                                ? const Icon(Icons.person, size: 20)
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    car.carRenter!.businessName ??
                                        car.carRenter!.user?.name ??
                                        'Car Renter',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (car.carRenter!.isVerified) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                ],
                              ],
                            ),
                            if (car.carRenter!.user?.phone != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    car.carRenter!.user!.phone!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => CarRenterPublicProfileScreen(
                                    carRenter: car.carRenter!,
                                  ),
                            ),
                          );
                        },
                        child: const Text('View Profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                ],

                // Price and book button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${car.dailyPrice.toStringAsFixed(0)} MAD',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          'per day',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _BookingDialog(car: car),
                        );
                      },
                      child: const Text('Book Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.directions_car, size: 64, color: Colors.grey),
      ),
    );
  }
}

class _FiltersBottomSheet extends StatefulWidget {
  final List<String> cities;
  final String? selectedCity;
  final double maxPrice;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(String?, double, DateTime?, DateTime?) onApply;

  const _FiltersBottomSheet({
    required this.cities,
    required this.selectedCity,
    required this.maxPrice,
    required this.startDate,
    required this.endDate,
    required this.onApply,
  });

  @override
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  late String? _selectedCity;
  late double _maxPrice;
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    _maxPrice = widget.maxPrice;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // City filter
          const Text('City', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCity,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'All cities',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All cities')),
              ...widget.cities.map(
                (city) => DropdownMenuItem(value: city, child: Text(city)),
              ),
            ],
            onChanged: (value) => setState(() => _selectedCity = value),
          ),
          const SizedBox(height: 16),

          // Price filter
          Text(
            'Max Price: ${_maxPrice.toStringAsFixed(0)} MAD/day',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Slider(
            value: _maxPrice,
            min: 100,
            max: 2000,
            divisions: 38,
            label: '${_maxPrice.toStringAsFixed(0)} MAD',
            onChanged: (value) => setState(() => _maxPrice = value),
          ),
          const SizedBox(height: 16),

          // Date range
          const Text(
            'Rental Period',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _startDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Start Date',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _endDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'End Date',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedCity, _maxPrice, _startDate, _endDate);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewRentalRequestDialog extends StatefulWidget {
  const _NewRentalRequestDialog();

  @override
  State<_NewRentalRequestDialog> createState() =>
      _NewRentalRequestDialogState();
}

class _NewRentalRequestDialogState extends State<_NewRentalRequestDialog> {
  final CarRentalService _service = CarRentalService();
  final OSRMService _osrmService = OSRMService();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Timer? _debounce;
  List<String> _citySuggestions = [];
  String? _selectedCity;
  List<Map<String, dynamic>> _carRenters = [];
  Map<String, dynamic>? _selectedRenter;
  List<ProvidedCarRental> _availableCars = [];
  ProvidedCarRental? _selectedCar;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoadingRenters = false;
  bool _isLoadingCars = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cityController.dispose();
    _notesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchCities(String query) async {
    if (query.trim().length < 2) {
      setState(() => _citySuggestions = []);
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final suggestions = await _osrmService.searchCities(query);
        if (mounted) {
          setState(() => _citySuggestions = suggestions);
        }
      } catch (e) {
        debugPrint('❌ Error searching cities: $e');
      }
    });
  }

  Future<void> _onCitySelected(String city) async {
    setState(() {
      _selectedCity = city;
      _cityController.text = city;
      _citySuggestions = [];
      _isLoadingRenters = true;
      _selectedRenter = null;
      _carRenters = [];
      _selectedCar = null;
      _availableCars = [];
    });

    try {
      // Pass the original city name - ilike will handle case-insensitive matching
      final renters = await _service.getCarRentersByCity(city);

      if (mounted) {
        setState(() {
          _carRenters = renters;
          _isLoadingRenters = false;
        });

        if (renters.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No car renters found in $city'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading car renters: $e');
      if (mounted) {
        setState(() => _isLoadingRenters = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading car renters: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRenterSelected(Map<String, dynamic>? renter) async {
    if (renter == null) return;

    setState(() {
      _selectedRenter = renter;
      _isLoadingCars = true;
      _selectedCar = null;
      _availableCars = [];
    });

    try {
      final cars = await _service.getAvailableCarsByRenterId(renter['id']);
      if (mounted) {
        setState(() {
          _availableCars = cars;
          _isLoadingCars = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading available cars: $e');
      if (mounted) {
        setState(() => _isLoadingCars = false);
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedCar == null || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = await _service.createRentalRequest(
        carRentalId: _selectedCar!.id,
        startDate: _startDate!,
        endDate: _endDate!,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (request != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rental request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error submitting request: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Rental Request',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // City autocomplete
                    const Text(
                      'City *',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_city),
                        suffixIcon:
                            _selectedCity != null
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _selectedCity = null;
                                      _cityController.clear();
                                      _citySuggestions = [];
                                      _carRenters = [];
                                      _selectedRenter = null;
                                      _availableCars = [];
                                      _selectedCar = null;
                                    });
                                  },
                                )
                                : null,
                      ),
                      onChanged: _searchCities,
                    ),
                    if (_citySuggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _citySuggestions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.location_on, size: 20),
                              title: Text(_citySuggestions[index]),
                              onTap:
                                  () =>
                                      _onCitySelected(_citySuggestions[index]),
                              dense: true,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Car Renter dropdown
                    const Text(
                      'Car Renter *',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Map<String, dynamic>>(
                      initialValue: _selectedRenter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select car renter',
                      ),
                      items:
                          _carRenters.map((renter) {
                            final name =
                                renter['business_name'] ??
                                renter['user']?['name'] ??
                                'Car Renter';
                            final rating = renter['rating'] ?? 0.0;
                            return DropdownMenuItem(
                              value: renter,
                              child: Row(
                                children: [
                                  Expanded(child: Text(name)),
                                  if (renter['is_verified'] == true)
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged:
                          _selectedCity == null || _isLoadingRenters
                              ? null
                              : _onRenterSelected,
                    ),
                    if (_isLoadingRenters)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                    const SizedBox(height: 16),

                    // Available Cars dropdown
                    const Text(
                      'Available Car *',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ProvidedCarRental>(
                      initialValue: _selectedCar,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select car',
                      ),
                      items:
                          _availableCars.map((car) {
                            return DropdownMenuItem(
                              value: car,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      car.displayName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${car.dailyPrice.toStringAsFixed(0)} MAD/day',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged:
                          _selectedRenter == null || _isLoadingCars
                              ? null
                              : (car) => setState(() => _selectedCar = car),
                    ),
                    if (_isLoadingCars)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                    const SizedBox(height: 16),

                    // Date range
                    const Text(
                      'Rental Period *',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() => _startDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _startDate != null
                                  ? DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(_startDate!)
                                  : 'Start Date',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _endDate ?? DateTime.now(),
                                firstDate: _startDate ?? DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() => _endDate = date);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _endDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_endDate!)
                                  : 'End Date',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    const Text(
                      'Notes (Optional)',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Add any special requests or notes...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingDialog extends StatefulWidget {
  final ProvidedCarRental car;

  const _BookingDialog({required this.car});

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  final CarRentalService _service = CarRentalService();
  final TextEditingController _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int? get _totalDays {
    if (_startDate == null || _endDate == null) return null;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  double? get _totalPrice {
    if (_totalDays == null) return null;
    return widget.car.dailyPrice * _totalDays!;
  }

  bool _isDateAvailable(DateTime date) {
    if (widget.car.unavailableFrom == null ||
        widget.car.unavailableUntil == null) {
      return true; // No restrictions
    }

    // Normalize dates to compare only year, month, day
    final unavailableStart = DateTime(
      widget.car.unavailableFrom!.year,
      widget.car.unavailableFrom!.month,
      widget.car.unavailableFrom!.day,
    );
    final unavailableEnd = DateTime(
      widget.car.unavailableUntil!.year,
      widget.car.unavailableUntil!.month,
      widget.car.unavailableUntil!.day,
    );

    final checkDate = DateTime(date.year, date.month, date.day);

    // Date is available if it's before the unavailable period starts
    // or after the unavailable period ends
    return checkDate.isBefore(unavailableStart) ||
        checkDate.isAfter(unavailableEnd);
  }

  /// Get the first available date for the date picker initial date
  /// This ensures the initialDate satisfies the selectableDayPredicate
  DateTime _getFirstAvailableDate(DateTime preferredDate) {
    if (_isDateAvailable(preferredDate)) {
      return preferredDate;
    }

    // If preferred date is unavailable, check if we should use the day after unavailable period
    if (widget.car.unavailableFrom != null &&
        widget.car.unavailableUntil != null) {
      final unavailableEnd = DateTime(
        widget.car.unavailableUntil!.year,
        widget.car.unavailableUntil!.month,
        widget.car.unavailableUntil!.day,
      );

      // Return the day after the unavailable period ends
      return unavailableEnd.add(const Duration(days: 1));
    }

    return preferredDate;
  }

  Future<void> _submitBooking() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = await _service.createRentalRequest(
        carRentalId: widget.car.id,
        startDate: _startDate!,
        endDate: _endDate!,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (request != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit booking. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error submitting booking: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Book Car Rental',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Car details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.blue[700], size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.car.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.car.dailyPrice.toStringAsFixed(0)} MAD/day',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unavailable period warning
                    if (widget.car.unavailableFrom != null &&
                        widget.car.unavailableUntil != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[400]!, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  color: Colors.red[800],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Unavailable Period',
                                    style: TextStyle(
                                      color: Colors.red[900],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 36),
                              child: Text(
                                '${DateFormat('MMM dd, yyyy').format(widget.car.unavailableFrom!)} - ${DateFormat('MMM dd, yyyy').format(widget.car.unavailableUntil!)}',
                                style: TextStyle(
                                  color: Colors.red[900],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 36),
                              child: Text(
                                'These dates will appear disabled in the calendar',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Date selection
                    const Text(
                      'Rental Period *',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Start date
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _getFirstAvailableDate(
                            _startDate ?? DateTime.now(),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          selectableDayPredicate: _isDateAvailable,
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                            // Reset end date if it's before the new start date
                            if (_endDate != null && _endDate!.isBefore(date)) {
                              _endDate = null;
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          _startDate != null
                              ? 'Start: ${DateFormat('MMM dd, yyyy').format(_startDate!)}'
                              : 'Select Start Date',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // End date
                    OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _getFirstAvailableDate(
                            _endDate ?? _startDate ?? DateTime.now(),
                          ),
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          selectableDayPredicate: _isDateAvailable,
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          _endDate != null
                              ? 'End: ${DateFormat('MMM dd, yyyy').format(_endDate!)}'
                              : 'Select End Date',
                          textAlign: TextAlign.left,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Price calculation
                    if (_totalDays != null && _totalPrice != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Duration:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '$_totalDays ${_totalDays == 1 ? 'day' : 'days'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Daily Rate:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${widget.car.dailyPrice.toStringAsFixed(0)} MAD',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Price:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${_totalPrice!.toStringAsFixed(0)} MAD',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Notes
                    const Text(
                      'Notes (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add any special requests or notes...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _isSubmitting || _startDate == null || _endDate == null
                        ? null
                        : _submitBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text(
                          'Submit Booking Request',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
