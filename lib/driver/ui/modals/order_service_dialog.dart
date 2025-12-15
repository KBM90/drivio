import 'package:drivio_app/common/helpers/geolocator_helper.dart';
import 'package:drivio_app/common/models/provided_service.dart';
import 'package:drivio_app/driver/services/service_order_service.dart';
import 'package:drivio_app/common/services/user_services.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class OrderServiceDialog extends StatefulWidget {
  final ProvidedService service;

  const OrderServiceDialog({super.key, required this.service});

  @override
  State<OrderServiceDialog> createState() => _OrderServiceDialogState();
}

class _OrderServiceDialogState extends State<OrderServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _serviceOrderService = ServiceOrderService();

  int _quantity = 1;
  String _preferredContactMethod = 'phone';
  bool _isLoading = false;
  String? _driverName;
  String? _driverPhone;
  LatLng? _driverLocation;

  @override
  void initState() {
    super.initState();
    _loadDriverInfo();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverInfo() async {
    try {
      final user = await UserService.getPersistanceCurrentUser();
      final location = await GeolocatorHelper.getCurrentLocation();

      if (mounted) {
        setState(() {
          _driverName = user?.name ?? 'Unknown';
          _driverPhone = user?.phone ?? '';
          _driverLocation = location;
        });
      }
    } catch (e) {
      debugPrint('Error loading driver info: $e');
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_driverName == null || _driverPhone == null) {
      _showError('Unable to load driver information');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? locationString;
      if (_driverLocation != null) {
        locationString =
            'POINT(${_driverLocation!.longitude} ${_driverLocation!.latitude})';
      }

      final order = await _serviceOrderService.createOrder(
        serviceId: widget.service.id,
        providerId: widget.service.providerId,
        driverName: _driverName!,
        driverPhone: _driverPhone!,
        driverLocation: locationString,
        quantity: _quantity,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        preferredContactMethod: _preferredContactMethod,
      );

      if (order != null && mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        _showSuccess();
      } else {
        _showError('Failed to create order');
      }
    } catch (e) {
      debugPrint('Error submitting order: $e');
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order placed successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
                    const Icon(
                      Icons.shopping_cart,
                      color: Colors.blue,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Order Service',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Service Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.service.price} ${widget.service.currency}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.service.providerName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Provider: ${widget.service.providerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Driver Info (Read-only)
                Text(
                  'Your Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoField('Name', _driverName ?? 'Loading...'),
                const SizedBox(height: 8),
                _buildInfoField('Phone', _driverPhone ?? 'Loading...'),
                const SizedBox(height: 20),

                // Quantity Selector
                Text(
                  'Quantity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.blue,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.blue,
                    ),
                    const Spacer(),
                    Text(
                      'Total: ${(widget.service.price * _quantity).toStringAsFixed(2)} ${widget.service.currency}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Preferred Contact Method
                Text(
                  'Preferred Contact Method',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildContactMethodChip('Phone Call', 'phone', Icons.phone),
                    _buildContactMethodChip(
                      'WhatsApp',
                      'whatsapp',
                      Icons.message,
                    ),
                    _buildContactMethodChip('SMS', 'sms', Icons.sms),
                  ],
                ),
                const SizedBox(height: 20),

                // Notes
                Text(
                  'Notes (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any special requests or notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isLoading
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
                              'Place Order',
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

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(value, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildContactMethodChip(String label, String value, IconData icon) {
    final isSelected = _preferredContactMethod == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.blue : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _preferredContactMethod = value);
        }
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
    );
  }
}
