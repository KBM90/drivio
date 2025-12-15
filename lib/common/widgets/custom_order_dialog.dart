import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/services/user_services.dart';
import 'package:drivio_app/driver/services/custom_service_request_service.dart';
import 'package:flutter/material.dart';

class CustomOrderDialog extends StatefulWidget {
  const CustomOrderDialog({super.key});

  @override
  State<CustomOrderDialog> createState() => _CustomOrderDialogState();
}

class _CustomOrderDialogState extends State<CustomOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String? _selectedCategory;
  String _contactMethod = 'phone';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Mechanic',
    'Cleaner',
    'Electrician',
    'Insurance',
    'Other',
  ];

  final List<Map<String, String>> _contactMethods = [
    {'value': 'phone', 'label': 'Phone Call'},
    {'value': 'whatsapp', 'label': 'WhatsApp'},
    {'value': 'sms', 'label': 'SMS'},
  ];

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get driver info
      final user = await UserService.getPersistanceCurrentUser();
      if (user == null) {
        throw Exception('User not found');
      }

      final driverName = user.name ?? 'Unknown Driver';
      final driverPhone = user.phone ?? '';

      // Get driver location
      String? driverLocation;
      final location = await GeolocatorHelper.getCurrentLocation();
      if (location != null) {
        driverLocation = 'POINT(${location.longitude} ${location.latitude})';
      }

      // Create custom service request
      final requestService = CustomServiceRequestService();
      final request = await requestService.createRequest(
        serviceName: _serviceNameController.text.trim(),
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
        driverName: driverName,
        driverPhone: driverPhone,
        driverLocation: driverLocation,
        quantity: int.parse(_quantityController.text),
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        preferredContactMethod: _contactMethod,
      );

      if (request != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Custom order placed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Close dialog and return success
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('❌ Error creating custom order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_shopping_cart,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Order',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Request a service or product',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category *',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items:
                      _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Service/Product Name
                TextFormField(
                  controller: _serviceNameController,
                  decoration: InputDecoration(
                    labelText: 'Service/Product Name *',
                    hintText: 'e.g., Tire Repair, Car Wash',
                    prefixIcon: const Icon(Icons.build),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    counterText: '',
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a service/product name';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe what you need...',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    counterText: '',
                  ),
                  maxLines: 3,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Quantity
                TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity < 1) {
                      return 'Quantity must be at least 1';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Additional Notes
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    hintText: 'Any additional information...',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    counterText: '',
                  ),
                  maxLines: 2,
                  maxLength: 300,
                ),
                const SizedBox(height: 16),

                // Contact Preference
                const Text(
                  'Preferred Contact Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      _contactMethods.map((method) {
                        final isSelected = _contactMethod == method['value'];
                        return ChoiceChip(
                          label: Text(method['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _contactMethod = method['value']!);
                            }
                          },
                          selectedColor: Colors.blue[100],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.blue[900] : Colors.black,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 24),

                // Info Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Service providers will see your request and contact you if they can help.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isSubmitting
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Submit Order',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
