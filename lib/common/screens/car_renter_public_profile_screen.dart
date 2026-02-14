import 'package:drivio_app/car_renter/models/car_renter.dart';
import 'package:drivio_app/car_renter/services/car_rental_service.dart';
import 'package:drivio_app/common/constants/app_theme.dart';
import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/common/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Public profile screen for car renter - viewable by clients/passengers
class CarRenterPublicProfileScreen extends StatefulWidget {
  final CarRenter carRenter;

  const CarRenterPublicProfileScreen({
    super.key,
    required this.carRenter,
  });

  @override
  State<CarRenterPublicProfileScreen> createState() =>
      _CarRenterPublicProfileScreenState();
}

class _CarRenterPublicProfileScreenState
    extends State<CarRenterPublicProfileScreen> {
  final CarRentalService _carRentalService = CarRentalService();
  List<ProvidedCarRental> _cars = [];
  bool _isLoadingCars = true;
  String _availabilityFilter = 'all'; // 'all', 'available', 'unavailable'

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final cars =
        await _carRentalService.getCarsByRenterId(widget.carRenter.id);
    if (mounted) {
      setState(() {
        _cars = cars;
        _isLoadingCars = false;
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
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final businessName =
        widget.carRenter.businessName ?? widget.carRenter.user?.name ?? 'Car Renter';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.renterProfile ?? 'Renter Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    backgroundImage:
                        widget.carRenter.user?.profileImagePath != null
                            ? NetworkImage(
                                widget.carRenter.user!.profileImagePath!,
                              )
                            : null,
                    child:
                        widget.carRenter.user?.profileImagePath == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.carRenter.isVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.verified ?? 'Verified',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Rating
            if (widget.carRenter.rating != null)
              _InfoCard(
                icon: Icons.star,
                title: l10n?.rating ?? 'Rating',
                value: '${widget.carRenter.rating!.toStringAsFixed(1)} / 5.0',
                iconColor: Colors.amber,
              ),

            // Total cars
            if (widget.carRenter.totalCars != null)
              _InfoCard(
                icon: Icons.directions_car,
                title: l10n?.totalCars ?? 'Total Cars',
                value:
                    '${widget.carRenter.totalCars} ${l10n?.vehicles ?? 'vehicles'}',
                iconColor: Colors.blue,
              ),

            // Location
            if (widget.carRenter.city != null)
              _InfoCard(
                icon: Icons.location_on,
                title: l10n?.location ?? 'Location',
                value: widget.carRenter.city!,
                iconColor: Colors.red,
              ),

            // Phone
            if (widget.carRenter.user?.phone != null)
              _InfoCard(
                icon: Icons.phone,
                title: l10n?.phone ?? 'Phone',
                value: widget.carRenter.user!.phone!,
                iconColor: Colors.green,
              ),

            const SizedBox(height: 24),

            // Contact button
            if (widget.carRenter.user?.phone != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.contactFunctionalityComingSoon ??
                              'Contact functionality coming soon!',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: Text(l10n?.contactRenter ?? 'Contact Renter'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Available Cars Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.availableCars ?? 'Available Cars',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isLoadingCars && _cars.isNotEmpty)
                  Text(
                    '${_filteredCars.length} ${_filteredCars.length == 1 ? 'car' : 'cars'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Availability Filter Chips
            if (!_isLoadingCars && _cars.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _availabilityFilterChip(
                      'All',
                      'all',
                    ),
                    _availabilityFilterChip(
                      l10n?.available ?? 'Available',
                      'available',
                    ),
                    _availabilityFilterChip(
                      l10n?.offline ?? 'Unavailable',
                      'unavailable',
                    ),
                  ],
                ),
              ),
            if (!_isLoadingCars && _cars.isNotEmpty)
              const SizedBox(height: 16),

            if (_isLoadingCars)
              const Center(child: CircularProgressIndicator())
            else if (_cars.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.noCarsAvailable ?? 'No cars available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else if (_filteredCars.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.noCarsMatchFilter ?? 'No cars match this filter',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredCars.length,
                itemBuilder: (context, index) {
                  final car = _filteredCars[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: car.images != null && car.images!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                car.images?.first ?? '',
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.directions_car),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.directions_car),
                            ),
                      title: Text(
                        car.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${car.dailyPrice.toStringAsFixed(0)} MAD/day',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            car.city,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      trailing: car.isAvailable
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n?.available ?? 'Available',
                                style: TextStyle(
                                  color: Colors.green[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n?.offline ?? 'Unavailable',
                                style: TextStyle(
                                  color: Colors.red[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
