import 'dart:io';
import 'package:drivio_app/common/models/car_brand.dart';
import 'package:drivio_app/driver/models/vehicle_document.dart';
import 'package:drivio_app/driver/models/vehicle.dart';
import 'package:drivio_app/driver/services/vehicle_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CarInfoScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const CarInfoScreen({super.key, this.vehicle});

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  XFile? _selectedImage;
  String? _uploadedImageUrl;

  Map<String, List<CarBrand>> _carBrands = {};
  List<String> _companies = [];
  List<CarBrand> _models = [];
  List<String> _colors = [];

  String? _selectedCompany;
  CarBrand? _selectedModel;
  String? _selectedColor;

  // ... existing code ...
  Vehicle? _existingVehicle;
  List<VehicleDocument> _documents = [];
  bool _isLoadingDocuments = false;

  @override
  void initState() {
    super.initState();
    _existingVehicle = widget.vehicle;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load car brands
      _carBrands = await VehicleService.getCarBrands();
      _companies = _carBrands.keys.toList()..sort();
      _colors = VehicleService.getCarColors();

      // If no vehicle passed, try to fetch it
      _existingVehicle ??= await VehicleService.getDriverVehicle();

      // If editing existing vehicle, populate fields and load documents
      if (_existingVehicle != null) {
        _licensePlateController.text = _existingVehicle!.licensePlate;
        _selectedColor = _existingVehicle!.color;

        if (_existingVehicle!.carBrand != null) {
          _selectedCompany = _existingVehicle!.carBrand!.company;
          _models = _carBrands[_selectedCompany] ?? [];
          _selectedModel = _models.firstWhere(
            (m) => m.id == _existingVehicle!.carBrand!.id,
            orElse: () => _models.first,
          );
        }
        await _loadDocuments();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDocuments() async {
    if (_existingVehicle == null) return;
    try {
      setState(() => _isLoadingDocuments = true);
      _documents = await VehicleService.getVehicleDocuments(
        _existingVehicle!.id,
      );
    } catch (e) {
      debugPrint('❌ Error loading documents: $e');
    } finally {
      setState(() => _isLoadingDocuments = false);
    }
  }

  Future<void> _showAddDocumentDialog() async {
    if (_existingVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save the vehicle first')),
      );
      return;
    }

    // Document types and their fields
    final Map<String, List<String>> documentTypeFields = {
      'Carte Grise': [
        'Registration Number',
        'Grey Card Number',
        'Vehicle Serial Number (VIN)',
      ],
      'Car Insurance': [
        'Insurance Policy Number',
        'Contract Number',
        'Vignette Reference Number',
      ],
      'Vignette': ['Vehicle Tax Identifier', 'Payment Receipt/Transaction ID'],
      'Technical Inspection': [
        'Inspection Report Number',
        'Inspection Center Number',
        'Vehicle Serial Number (VIN)',
      ],
    };

    String? selectedDocType;
    DateTime? expiryDate;
    XFile? docImage;
    bool isUploading = false;
    Map<String, TextEditingController> fieldControllers = {};

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              // Initialize controllers for selected document type
              if (selectedDocType != null && fieldControllers.isEmpty) {
                for (var field in documentTypeFields[selectedDocType]!) {
                  fieldControllers[field] = TextEditingController();
                }
              }

              return AlertDialog(
                title: const Text('Add Document'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Document Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedDocType,
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            documentTypeFields.keys.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDocType = value;
                            // Clear and reinitialize controllers
                            fieldControllers.forEach(
                              (key, controller) => controller.dispose(),
                            );
                            fieldControllers.clear();
                            if (value != null) {
                              for (var field in documentTypeFields[value]!) {
                                fieldControllers[field] =
                                    TextEditingController();
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dynamic fields based on selected type
                      if (selectedDocType != null) ...[
                        ...documentTypeFields[selectedDocType]!.map((
                          fieldName,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: fieldControllers[fieldName],
                              decoration: InputDecoration(
                                labelText: fieldName,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          );
                        }),
                      ],

                      // Expiry Date
                      ListTile(
                        title: Text(
                          expiryDate == null
                              ? 'Select Expiry Date'
                              : 'Expires: ${expiryDate!.toLocal().toString().split(' ')[0]}',
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() => expiryDate = date);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Image Upload
                      GestureDetector(
                        onTap: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setDialogState(() => docImage = image);
                          }
                        },
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              docImage != null
                                  ? Image.file(
                                    File(docImage!.path),
                                    fit: BoxFit.cover,
                                  )
                                  : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload_file),
                                      Text('Tap to upload image'),
                                    ],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Dispose controllers
                      fieldControllers.forEach(
                        (key, controller) => controller.dispose(),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isUploading
                            ? null
                            : () async {
                              if (selectedDocType == null ||
                                  expiryDate == null ||
                                  docImage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill all required fields',
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Validate all fields are filled
                              bool allFieldsFilled = fieldControllers.values
                                  .every((c) => c.text.isNotEmpty);
                              if (!allFieldsFilled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill all document fields',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                setDialogState(() => isUploading = true);

                                // Upload image first
                                final imageId =
                                    await VehicleService.uploadDocumentImage(
                                      docImage!,
                                    );

                                // Collect metadata
                                Map<String, dynamic> metadata = {};
                                fieldControllers.forEach((key, controller) {
                                  metadata[key] = controller.text;
                                });

                                // Add document record
                                await VehicleService.addVehicleDocument(
                                  vehicleId: _existingVehicle!.id,
                                  documentName: selectedDocType!,
                                  documentType: selectedDocType!,
                                  expiringDate: expiryDate!,
                                  imageId: imageId,
                                  metadata: metadata,
                                );

                                if (mounted) {
                                  // Dispose controllers
                                  fieldControllers.forEach(
                                    (key, controller) => controller.dispose(),
                                  );
                                  Navigator.pop(context);
                                  _loadDocuments(); // Refresh list
                                }
                              } catch (e) {
                                debugPrint('❌ Error adding document: $e');
                                setDialogState(() => isUploading = false);
                              }
                            },
                    child:
                        isUploading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(),
                            )
                            : const Text('Save'),
                  ),
                ],
              );
            },
          ),
    );
  }

  // ... existing _pickImage, _saveVehicle, build method ...

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car model')),
      );
      return;
    }

    if (_selectedColor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a color')));
      return;
    }

    try {
      setState(() => _isSaving = true);

      // Upload image if selected
      if (_selectedImage != null) {
        _uploadedImageUrl = await VehicleService.uploadVehicleImage(
          _selectedImage!,
        );
      }

      if (_existingVehicle != null) {
        // Update existing vehicle
        await VehicleService.updateVehicle(
          vehicleId: _existingVehicle!.id,
          carBrandId: _selectedModel!.id,
          color: _selectedColor!,
          licensePlate: _licensePlateController.text.trim(),
        );

        // Save image reference if uploaded
        if (_uploadedImageUrl != null) {
          await VehicleService.saveVehicleImage(
            vehicleId: _existingVehicle!.id,
            imagePath: _uploadedImageUrl!,
          );
        }
      } else {
        // Create new vehicle
        final newVehicle = await VehicleService.createVehicle(
          carBrandId: _selectedModel!.id,
          licensePlate: _licensePlateController.text.trim(),
          color: _selectedColor!,
        );

        // Save image reference if uploaded
        if (_uploadedImageUrl != null) {
          await VehicleService.saveVehicleImage(
            vehicleId: newVehicle.id,
            imagePath: _uploadedImageUrl!,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle saved successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('❌ Error saving vehicle: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving vehicle: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingVehicle != null ? 'Edit Vehicle' : 'Add Vehicle'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Picker
                      _buildImagePicker(),
                      const SizedBox(height: 24),

                      // Company Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCompany,
                        decoration: const InputDecoration(
                          labelText: 'Car Brand',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _companies.map((company) {
                              return DropdownMenuItem(
                                value: company,
                                child: Text(company),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCompany = value;
                            _models = _carBrands[value] ?? [];
                            _selectedModel = null; // Reset model selection
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a car brand';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Model Dropdown
                      DropdownButtonFormField<CarBrand>(
                        initialValue: _selectedModel,
                        decoration: const InputDecoration(
                          labelText: 'Car Model',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _models.map((model) {
                              return DropdownMenuItem(
                                value: model,
                                child: Text(model.model),
                              );
                            }).toList(),
                        onChanged:
                            _selectedCompany == null
                                ? null
                                : (value) {
                                  setState(() => _selectedModel = value);
                                },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a car model';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Color Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedColor,
                        decoration: const InputDecoration(
                          labelText: 'Color',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _colors.map((color) {
                              return DropdownMenuItem(
                                value: color,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _getColorFromName(color),
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(color),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedColor = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a color';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // License Plate
                      TextFormField(
                        controller: _licensePlateController,
                        decoration: const InputDecoration(
                          labelText: 'License Plate',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter license plate';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Documents Section
                      if (_existingVehicle != null) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Documents',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle),
                              onPressed: _showAddDocumentDialog,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _isLoadingDocuments
                            ? const Center(child: CircularProgressIndicator())
                            : _documents.isEmpty
                            ? const Text(
                              'No documents added yet',
                              style: TextStyle(color: Colors.grey),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _documents.length,
                              itemBuilder: (context, index) {
                                final doc = _documents[index];
                                final isExpired =
                                    doc.isExpired ||
                                    doc.expiringDate.isBefore(DateTime.now());
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.description),
                                    title: Text(doc.documentName),
                                    subtitle: Text(
                                      'Expires: ${doc.expiringDate.toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        color:
                                            isExpired
                                                ? Colors.red
                                                : Colors.green,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await VehicleService.deleteVehicleDocument(
                                          doc.id,
                                        );
                                        _loadDocuments();
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                        const SizedBox(height: 24),
                      ],

                      // Save Button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveVehicle,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child:
                            _isSaving
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  _existingVehicle != null
                                      ? 'Update Vehicle'
                                      : 'Save Vehicle',
                                ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child:
            _selectedImage != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImage!.path),
                    fit: BoxFit.cover,
                  ),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add vehicle photo',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'silver':
        return Colors.grey[300]!;
      case 'gray':
        return Colors.grey;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'brown':
        return Colors.brown;
      case 'green':
        return Colors.green;
      case 'beige':
        return const Color(0xFFF5F5DC);
      case 'orange':
        return Colors.orange;
      case 'gold':
        return const Color(0xFFFFD700);
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    super.dispose();
  }
}
