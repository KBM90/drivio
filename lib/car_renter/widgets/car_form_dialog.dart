import 'package:flutter/material.dart';
import 'package:drivio_app/car_renter/services/car_rental_service.dart';
import 'package:drivio_app/common/models/car_brand.dart';
import 'package:drivio_app/common/models/provided_car_rental.dart';
import 'package:drivio_app/common/l10n/app_localizations.dart';

class CarFormDialog extends StatefulWidget {
  final int renterId;
  final CarRentalService service;
  final ProvidedCarRental? car;
  final VoidCallback onSaved;

  const CarFormDialog({
    super.key,
    required this.renterId,
    required this.service,
    this.car,
    required this.onSaved,
  });

  @override
  State<CarFormDialog> createState() => _CarFormDialogState();
}

class _CarFormDialogState extends State<CarFormDialog> {
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
        SnackBar(
            content: Text(
                AppLocalizations.of(context)?.pleaseSelectCarBrand ??
                    'Please select a car brand')),
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
          plateNumber: _plateController.text.trim().isEmpty
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
          plateNumber: _plateController.text.trim().isEmpty
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
      title: Text(widget.car == null
          ? (AppLocalizations.of(context)?.add ?? 'Add Car')
          : (AppLocalizations.of(context)?.editCar ?? 'Edit Car')),
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
                  initialValue: _carBrandController.text.isNotEmpty
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
                  displayStringForOption: (CarBrand brand) =>
                      '${brand.company} ${brand.model}',
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
                          return AppLocalizations.of(context)
                                  ?.pleaseSelectCarBrand ??
                              'Please select a car brand';
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
          child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.car == null
                  ? (AppLocalizations.of(context)?.add ?? 'Add')
                  : (AppLocalizations.of(context)?.save ?? 'Save')),
        ),
      ],
    );
  }
}
