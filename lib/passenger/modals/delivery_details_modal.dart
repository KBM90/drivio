import 'package:drivio_app/common/providers/device_location_provider.dart';
import 'package:drivio_app/passenger/services/delivery_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeliveryDetailsModal extends StatefulWidget {
  final String category;

  const DeliveryDetailsModal({super.key, required this.category});

  @override
  State<DeliveryDetailsModal> createState() => _DeliveryDetailsModalState();
}

class _DeliveryDetailsModalState extends State<DeliveryDetailsModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _pickupNotesController = TextEditingController();
  final _dropoffNotesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _pickupNotesController.dispose();
    _dropoffNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Get actual locations from a location picker or current location
      // For now, we'll use dummy locations or handle it in the service if possible
      // Ideally, this modal should be opened AFTER selecting locations, or include location picking.
      // Assuming for this step we just create the request record.

      final deviceLocationProvider = Provider.of<DeviceLocationProvider>(
        context,
        listen: false,
      );
      final currentLocation = deviceLocationProvider.currentLocation;

      if (currentLocation == null) {
        throw Exception('Current location not available');
      }

      await DeliveryService.createDeliveryRequest(
        category: widget.category,
        description: _descriptionController.text,
        pickupNotes: _pickupNotesController.text,
        dropoffNotes: _dropoffNotesController.text,
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude,
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery request created successfully!'),
          ),
        );
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.category} Delivery Details',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'What do you want?',
                hintText: 'e.g., 2 large pizzas, keys, documents',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe the item';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pickupNotesController,
              decoration: const InputDecoration(
                labelText: 'Pickup Notes (Optional)',
                hintText: 'e.g., Ring doorbell, wait at lobby',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dropoffNotesController,
              decoration: const InputDecoration(
                labelText: 'Dropoff Notes (Optional)',
                hintText: 'e.g., Leave at front desk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue[800],
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : const Text(
                        'Confirm Request',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
