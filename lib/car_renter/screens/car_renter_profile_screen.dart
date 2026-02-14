import 'dart:io';

import 'package:drivio_app/car_renter/models/car_renter.dart';
import 'package:drivio_app/car_renter/services/car_rental_service.dart';
import 'package:drivio_app/common/constants/app_theme.dart';
import 'package:drivio_app/common/models/car_brand.dart';
import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/common/l10n/app_localizations.dart';
import 'package:drivio_app/driver/services/driver_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drivio_app/car_renter/widgets/car_form_dialog.dart';

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
  bool _isUpdatingProfile = false;

  // Editable fields
  String? _businessName;
  String? _phone;
  String? _profileImageUrl;
  XFile? _localProfileImage;

  @override
  void initState() {
    super.initState();
    _businessName =
        widget.carRenter.businessName ?? widget.carRenter.user?.name;
    _phone = widget.carRenter.user?.phone;
    _profileImageUrl = widget.carRenter.user?.profileImagePath;
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

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _localProfileImage = image;
      });
      await _saveProfileImage();
    }
  }

  Future<void> _saveProfileImage() async {
    try {
      setState(() => _isUpdatingProfile = true);

      String? profileImageUrl;
      if (_localProfileImage != null) {
        profileImageUrl = await DriverService.uploadProfileImage(
          _localProfileImage!.path,
        );
      }

      if (profileImageUrl != null) {
        await DriverService.updateUserInfo(profileImagePath: profileImageUrl);
        if (mounted) {
          setState(() {
            _profileImageUrl = profileImageUrl;
            _localProfileImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.profilePictureUpdated ??
                    'Profile picture updated',
              ),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorUpdatingProfilePicture ?? 'Error updating profile picture'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingProfile = false);
      }
    }
  }

  Future<void> _editBusinessName() async {
    final controller = TextEditingController(text: _businessName ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)?.editBusinessName ??
                'Edit Business Name',
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText:
                  AppLocalizations.of(context)?.businessName ?? 'Business Name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      setState(() => _isUpdatingProfile = true);

      await AuthService.ensureValidSession();
      await Supabase.instance.client
          .from('car_renters')
          .update({
            'business_name': result,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.carRenter.id);

      if (mounted) {
        setState(() => _businessName = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.businessNameUpdated ??
                  'Business name updated',
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorUpdatingBusinessName ?? 'Error updating business name'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingProfile = false);
      }
    }
  }

  Future<void> _editPhone() async {
    final controller = TextEditingController(text: _phone ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)?.editPhoneNumber ??
                'Edit Phone Number',
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.phone ?? 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      setState(() => _isUpdatingProfile = true);
      await DriverService.updateUserInfo(phone: result);

      if (mounted) {
        setState(() => _phone = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.phoneNumberUpdated ??
                  'Phone number updated',
            ),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorUpdatingPhone ?? 'Error updating phone'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
      setState(() => _isUpdatingProfile = false);
      }
    }
  }

  void _showAddCarDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CarFormDialog(
            renterId: widget.carRenter.id,
            service: _carRentalService,
            onSaved: _loadCars,
          ),
    );
  }

  void _showEditCarDialog(ProvidedCarRental car) {
    showDialog(
      context: context,
      builder:
          (context) => CarFormDialog(
            renterId: widget.carRenter.id,
            service: _carRentalService,
            car: car,
            onSaved: _loadCars,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.renterProfile ?? 'Renter Profile',
        ),
        actions: [
          if (_isUpdatingProfile)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue[100],
                        backgroundImage:
                            _localProfileImage != null
                                ? FileImage(File(_localProfileImage!.path))
                                : _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                        child:
                            _localProfileImage == null &&
                                    _profileImageUrl == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          radius: 18,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _pickProfileImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _businessName ??
                              widget.carRenter.user?.name ??
                              'Car Renter',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: _editBusinessName,
                        tooltip: 'Edit business name',
                      ),
                    ],
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
                            AppLocalizations.of(context)?.verified ??
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
                title: AppLocalizations.of(context)?.rating ?? 'Rating',
                value: '${widget.carRenter.rating!.toStringAsFixed(1)} / 5.0',
                iconColor: Colors.amber,
              ),

            // Total cars
            if (widget.carRenter.totalCars != null)
              _InfoCard(
                icon: Icons.directions_car,
                title: AppLocalizations.of(context)?.totalCars ?? 'Total Cars',
                value:
                    '${widget.carRenter.totalCars} ${AppLocalizations.of(context)?.vehicles ?? 'vehicles'}',
                iconColor: Colors.blue,
              ),

            // Location
            if (widget.carRenter.city != null)
              _InfoCard(
                icon: Icons.location_on,
                title: AppLocalizations.of(context)?.location ?? 'Location',
                value: widget.carRenter.city!,
                iconColor: Colors.red,
              ),

            // Phone
            if (_phone != null && _phone!.isNotEmpty)
              _InfoCard(
                icon: Icons.phone,
                title: AppLocalizations.of(context)?.phone ?? 'Phone',
                value: _phone!,
                iconColor: Colors.green,
                onTap: _editPhone,
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
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                                context,
                              )?.contactFunctionalityComingSoon ??
                              'Contact functionality coming soon!',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: Text(
                    AppLocalizations.of(context)?.contactRenter ??
                        'Contact Renter',
                  ),
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
                          title: Text(
                            AppLocalizations.of(context)?.logOut ?? 'Logout',
                          ),
                          content: Text(
                            AppLocalizations.of(context)?.confirmLogout ??
                                'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                AppLocalizations.of(context)?.logOut ??
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
                Text(
                  AppLocalizations.of(context)?.availableCars ??
                      'Available Cars',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddCarDialog,
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context)?.add ?? 'Add Car'),
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
                            AppLocalizations.of(context)?.noCarsAvailable ??
                                'No cars available',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                : _CarsTable(
                  cars: _cars,
                  onEditCar: _showEditCarDialog,
                  onDeleteCar: (car) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(
                              AppLocalizations.of(context)?.deleteCar ??
                                  'Delete Car',
                            ),
                            content: Text(
                              AppLocalizations.of(context)?.confirmDeleteCar ??
                                  'Are you sure you want to delete this car?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      await _carRentalService.deleteCarRental(car.id);
                      await _loadCars();
                    }
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

  final void Function(ProvidedCarRental car) onEditCar;
  final void Function(ProvidedCarRental car) onDeleteCar;

  const _CarsTable({
    required this.cars,
    required this.onEditCar,
    required this.onDeleteCar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          columns: [
            DataColumn(
              label: Text(
                AppLocalizations.of(context)?.translate('car') ?? 'Car',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                AppLocalizations.of(context)?.color ?? 'Color',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                AppLocalizations.of(context)?.pricePerDay ?? 'Price/Day',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                AppLocalizations.of(context)?.status ?? 'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                AppLocalizations.of(context)?.actions ?? 'Actions',
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
                          color: AppTheme.primaryColor,
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
                          car.isAvailable
                              ? (AppLocalizations.of(context)?.available ??
                                  'Available')
                              : (AppLocalizations.of(context)?.rented ??
                                  'Rented'),
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
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => onEditCar(car),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                            onPressed: () => onDeleteCar(car),
                          ),
                        ],
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


