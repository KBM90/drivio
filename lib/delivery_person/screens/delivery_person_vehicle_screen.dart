import 'package:drivio_app/common/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryPersonVehicleScreen extends StatefulWidget {
  const DeliveryPersonVehicleScreen({super.key});

  @override
  State<DeliveryPersonVehicleScreen> createState() =>
      _DeliveryPersonVehicleScreenState();
}

class _DeliveryPersonVehicleScreenState
    extends State<DeliveryPersonVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  int? _deliveryPersonId;

  String? _vehicleType;
  final TextEditingController _plateController = TextEditingController();

  final List<String> _vehicleTypes = ['bike', 'car'];

  @override
  void initState() {
    super.initState();
    _fetchVehicleDetails();
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _fetchVehicleDetails() async {
    try {
      final id = await AuthService.getDeliveryPersonId();
      if (id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Could not find delivery profile'),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      _deliveryPersonId = id;

      final data =
          await Supabase.instance.client
              .from('delivery_persons')
              .select('vehicle_type, vehicle_plate')
              .eq('id', id)
              .single();

      if (mounted) {
        setState(() {
          _vehicleType = data['vehicle_type'] as String?;
          _plateController.text = data['vehicle_plate'] as String? ?? '';

          // Ensure valid initial value for dropdown
          if (_vehicleType != null && !_vehicleTypes.contains(_vehicleType)) {
            // If unknown type, defaulting to null or adding it could be options.
            // For now, let's reset if invalid, or keep as is if we want to allow other types but just not select them in dropdown
            if (_vehicleTypes.contains(_vehicleType!.toLowerCase())) {
              _vehicleType = _vehicleType!.toLowerCase();
            } else {
              _vehicleType = null;
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vehicle details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load vehicle details: $e')),
        );
      }
    }
  }

  Future<void> _saveVehicleDetails() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deliveryPersonId == null) return;

    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client
          .from('delivery_persons')
          .update({
            'vehicle_type': _vehicleType,
            'vehicle_plate': _plateController.text.trim(),
          })
          .eq('id', _deliveryPersonId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle details updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving vehicle details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
      appBar: AppBar(title: const Text('Vehicle Details')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update your vehicle information below.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Vehicle Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _vehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                        ),
                        items:
                            _vehicleTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type[0].toUpperCase() + type.substring(1),
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _vehicleType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a vehicle type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Vehicle Plate TextField
                      TextFormField(
                        controller: _plateController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Plate Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.confirmation_number),
                          hintText: 'e.g., ABC-123',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter vehicle plate number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveVehicleDetails,
                          child:
                              _isSaving
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
