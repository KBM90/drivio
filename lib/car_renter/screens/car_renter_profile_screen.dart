import 'package:drivio_app/car_renter/models/car_renter.dart';
import 'package:drivio_app/car_renter/services/car_rental_service.dart';
import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';

class CarRenterProfileScreen extends StatefulWidget {
  final CarRenter carRenter;

  const CarRenterProfileScreen({super.key, required this.carRenter});

  @override
  State<CarRenterProfileScreen> createState() => _CarRenterProfileScreenState();
}

class _CarRenterProfileScreenState extends State<CarRenterProfileScreen> {
  final CarRentalService _carRentalService = CarRentalService();
  List<ProvidedCarRental> _cars = [];
  bool _isLoadingCars = true;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final cars = await _carRentalService.getCarsByRenterId(widget.carRenter.id);
    if (mounted) {
      setState(() {
        _cars = cars;
        _isLoadingCars = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Renter Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
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
                    widget.carRenter.businessName ??
                        widget.carRenter.user?.name ??
                        'Car Renter',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
                            'Verified',
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
                title: 'Rating',
                value: '${widget.carRenter.rating!.toStringAsFixed(1)} / 5.0',
                iconColor: Colors.amber,
              ),

            // Total cars
            if (widget.carRenter.totalCars != null)
              _InfoCard(
                icon: Icons.directions_car,
                title: 'Total Cars',
                value: '${widget.carRenter.totalCars} vehicles',
                iconColor: Colors.blue,
              ),

            // Location
            if (widget.carRenter.city != null)
              _InfoCard(
                icon: Icons.location_on,
                title: 'Location',
                value: widget.carRenter.city!,
                iconColor: Colors.red,
              ),

            // Phone
            if (widget.carRenter.user?.phone != null)
              _InfoCard(
                icon: Icons.phone,
                title: 'Phone',
                value: widget.carRenter.user!.phone!,
                iconColor: Colors.green,
                onTap: () {
                  // TODO: Implement phone call functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Call functionality coming soon!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Contact button
            if (widget.carRenter.user?.phone != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement contact functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact functionality coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Contact Renter'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true && mounted) {
                    await AuthService.signOut();
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Available Cars Section
            Row(
              children: [
                Icon(Icons.directions_car, color: Colors.grey[700]),
                const SizedBox(width: 8),
                const Text(
                  'Available Cars',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _isLoadingCars
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
                : _cars.isEmpty
                ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.car_rental,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No cars available',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : _CarsTable(cars: _cars),
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
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarsTable extends StatelessWidget {
  final List<ProvidedCarRental> cars;

  const _CarsTable({required this.cars});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: const [
            DataColumn(
              label: Text('Car', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text(
                'Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Price/Day',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows:
              cars.map((car) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        car.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (car.color != null) ...[
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getColorFromName(car.color!),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(car.color ?? '-'),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        '${car.dailyPrice.toStringAsFixed(0)} MAD',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              car.isAvailable
                                  ? Colors.green[50]
                                  : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          car.isAvailable ? 'Available' : 'Rented',
                          style: TextStyle(
                            color:
                                car.isAvailable
                                    ? Colors.green[700]
                                    : Colors.red[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    final colorMap = {
      'white': Colors.white,
      'black': Colors.black,
      'gray': Colors.grey,
      'grey': Colors.grey,
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'orange': Colors.orange,
      'brown': Colors.brown,
      'silver': Colors.grey[300]!,
    };

    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }
}
