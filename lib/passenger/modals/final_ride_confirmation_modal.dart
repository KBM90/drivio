import 'package:drivio_app/common/constants/transport_constants.dart';
import 'package:drivio_app/common/helpers/price_helpers.dart';
import 'package:drivio_app/common/models/payment_method.dart';
import 'package:drivio_app/common/models/transporttype.dart';
import 'package:drivio_app/common/services/payment_methods_services.dart';
import 'package:flutter/material.dart';

class FinalRideConfirmationModal extends StatefulWidget {
  final double distance;
  final TransportType initialTransport;
  final Function(
    double price,
    TransportType transportType,
    PaymentMethod paymentMethod,
  )
  onConfirm;

  const FinalRideConfirmationModal({
    super.key,
    required this.distance,
    required this.initialTransport,
    required this.onConfirm,
  });

  @override
  State<FinalRideConfirmationModal> createState() =>
      _FinalRideConfirmationModalState();
}

class _FinalRideConfirmationModalState
    extends State<FinalRideConfirmationModal> {
  late TransportType selectedTransport;
  late PaymentMethod _paymentMethod;
  final TextEditingController _priceController = TextEditingController();
  late double _suggestedPrice;
  String? _errorText;

  List<PaymentMethod> filteredPaymentMethods = [];

  @override
  void initState() {
    super.initState();
    selectedTransport = widget.initialTransport;
    _calculateSuggestedPrice();
    _loadUserPaymentMethods();
  }

  void _calculateSuggestedPrice() {
    _suggestedPrice = PriceHelpers().calculateSuggestedPrice(
      distance: widget.distance,
      priceMultiplier: selectedTransport.priceMultiplier!,
    );
  }

  Future<void> _loadUserPaymentMethods() async {
    final paymentMethods = await PaymentMethodService.fetchPaymentMethods();

    setState(() {
      filteredPaymentMethods = paymentMethods;
      if (filteredPaymentMethods.isNotEmpty) {
        _paymentMethod = filteredPaymentMethods.first;
      }
    });
  }

  void _onConfirm() {
    double? enteredPrice = double.tryParse(_priceController.text);

    // Use suggested price if input is empty
    if (enteredPrice == null && _priceController.text.isEmpty) {
      enteredPrice = _suggestedPrice;
    }

    if (enteredPrice == null) {
      setState(() => _errorText = "Invalid price");
      return;
    }

    if (enteredPrice < 0) {
      setState(() => _errorText = "Price cannot be negative");
      return;
    }

    widget.onConfirm(enteredPrice, selectedTransport, _paymentMethod);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Wrap(
        children: [
          Center(
            child: Column(
              children: [
                // Price Display
                Text(
                  "${_suggestedPrice.toStringAsFixed(2)} MAD",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  "Suggested Price",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Info Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn(
                      "Distance",
                      "${widget.distance.toStringAsFixed(2)} km",
                    ),
                    _buildInfoColumn("Transport", selectedTransport.name),
                  ],
                ),
                const SizedBox(height: 24),

                // Price Input
                TextField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Offer your price',
                    hintText: _suggestedPrice.toStringAsFixed(2),
                    errorText: _errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: 'MAD',
                  ),
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Transport Dropdown
                DropdownButtonFormField<TransportType>(
                  initialValue: selectedTransport,
                  decoration: InputDecoration(
                    labelText: 'Transport Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  items:
                      TransportConstants.transports.map((type) {
                        return DropdownMenuItem<TransportType>(
                          value: type,
                          child: Text(type.name),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedTransport = value;
                        _priceController.clear();
                        _calculateSuggestedPrice();
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Payment Method Dropdown
                filteredPaymentMethods.isEmpty
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<PaymentMethod>(
                      initialValue: filteredPaymentMethods.first,
                      decoration: InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items:
                          filteredPaymentMethods.map((method) {
                            return DropdownMenuItem<PaymentMethod>(
                              value: method,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.payment,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(method.name),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _paymentMethod = value;
                          });
                        }
                      },
                    ),

                const SizedBox(height: 24),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _onConfirm,
                    child: const Text(
                      "Confirm Request",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
