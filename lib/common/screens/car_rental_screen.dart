import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/car_renter/services/car_rental_service.dart';
import 'package:drivio_app/car_renter/screens/car_renter_profile_screen.dart';
import 'package:flutter/material.dart';

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
                                  (context) => CarRenterProfileScreen(
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking feature coming soon!'),
                            duration: Duration(seconds: 2),
                          ),
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
            value: _selectedCity,
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
