import 'dart:io';
import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/provider/services/provided_services_service.dart';
import 'package:drivio_app/provider/services/service_provider_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddServiceScreen extends StatefulWidget {
  const AddServiceScreen({super.key});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  // final _imageUrlController = TextEditingController(); // Removed

  String? _selectedCategory;
  String? _providerType;
  File? _imageFile;
  bool _isLoading = false;

  List<String> _categories = [
    'Maintenance',
    'Cleaning',
    'Repair',
    'Inspection',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProviderType();
  }

  Future<void> _fetchProviderType() async {
    try {
      final userId = await AuthService.getInternalUserId();
      if (userId != null) {
        final serviceProviderService = ServiceProviderService();
        final providerType = await serviceProviderService.getProviderType(
          userId,
        );

        if (providerType != null && mounted) {
          setState(() {
            _providerType = providerType;
            _updateCategories();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching provider type: $e');
    }
  }

  void _updateCategories() {
    switch (_providerType) {
      case 'mechanic':
        _categories = [
          'Engine Repair',
          'Brake Service',
          'Oil Change',
          'Tire Service',
          'Diagnostics',
          'Other',
        ];

        break;
      case 'cleaner':
        _categories = ['Interior Cleaning', 'Exterior Wash', 'Upholstery'];
        break;
      case 'electrician':
        _categories = [
          'Battery Service',
          'Wiring',
          'Lights',
          'Audio System',
          'Other',
        ];
        break;
      case 'insurance':
        _categories = [
          'Personal Injury',
          'Third Party Insurance',
          'Full Coverage',
          'Assistance',
          'Conducteur Coverage',
          'Personal belongings coverage',
          'Legal protection',
          'Other',
        ];
        break;
      case 'car_auto_parts':
        _categories = [
          'Engine Parts',
          'Body Parts',
          'Electrical',
          'Wheels & Tires',
          'Accessories',
          'Other',
        ];
        break;
      default:
        _categories = [
          'Maintenance',
          'Cleaning',
          'Repair',
          'Inspection',
          'Other',
        ];
    }
    // Reset selected category if it's not in the new list
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    // _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    // if (_imageFile == null) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text('Please select an image')));
    //   return;
    // }

    setState(() => _isLoading = true);

    try {
      final serviceService = ProvidedServicesService();
      await serviceService.createService(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory!,
        imageFile: _imageFile,
        providerType: _providerType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service created successfully!')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating service: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_providerType != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Provider Type: ${_providerType!.toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText:
                      _providerType == 'car_auto_parts'
                          ? 'Part Name'
                          : 'Service Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.build),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items:
                    _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (MAD)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child:
                      _imageFile != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                          : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to add service image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Create Service',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
