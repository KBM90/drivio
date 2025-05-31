import 'package:drivio_app/common/constants/payment_methods_constants.dart';
import 'package:drivio_app/common/constants/transport_constants.dart';
import 'package:drivio_app/common/helpers/price_helpers.dart';
import 'package:drivio_app/common/models/payment_method.dart';
import 'package:drivio_app/common/models/transporttype.dart';
import 'package:drivio_app/common/services/user_payment_methods_services.dart';
import 'package:flutter/material.dart';

class SuggestedPriceModal extends StatefulWidget {
  final double distance;
  final TransportType initialTransport;
  final Function(
    double price,
    TransportType transportType,
    PaymentMethod paymentMethod,
  )
  onConfirm;

  const SuggestedPriceModal({
    super.key,
    required this.distance,
    required this.initialTransport,
    required this.onConfirm,
  });

  @override
  State<SuggestedPriceModal> createState() => _SuggestedPriceModalState();
}

class _SuggestedPriceModalState extends State<SuggestedPriceModal> {
  late TransportType selectedTransport;
  late PaymentMethod _paymentMethod;
  final TextEditingController _priceController = TextEditingController();
  late double _suggestedPrice;

  List<PaymentMethod> filteredPaymentMethods = [];

  @override
  void initState() {
    super.initState();
    selectedTransport = widget.initialTransport;
    _suggestedPrice = PriceHelpers().calculateSuggestedPrice(
      distance: widget.distance,
      priceMultiplier: selectedTransport.priceMultiplier!,
    );
    _loadUserPaymentMethods();
  }

  Future<void> _loadUserPaymentMethods() async {
    final userPaymentMethods =
        await PaymentMethodService.fetchUserPaymentMethods();

    // Get IDs of the user's allowed payment methods
    final allowedIds = userPaymentMethods.map((e) => e.paymentMethodId).toSet();

    // Filter the constants list based on those IDs
    setState(() {
      filteredPaymentMethods =
          PaymentMethodsConstants.paymentMethods
              .where((method) => allowedIds.contains(method.id))
              .toList();
      _paymentMethod = filteredPaymentMethods.first;
    });
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _suggestedPrice.toStringAsFixed(2),

                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.attach_money, size: 32, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Suggested Price",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text("Distance: ${widget.distance.toStringAsFixed(2)} km"),
                const SizedBox(height: 6),
                Text("Selected: ${selectedTransport.name}"),
                Text(
                  selectedTransport.description!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _priceController,

                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Enter your price',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on),
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<TransportType>(
                  value: selectedTransport,
                  decoration: const InputDecoration(
                    labelText: 'Select Transport Type',
                    border: OutlineInputBorder(),
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
                        _suggestedPrice = PriceHelpers()
                            .calculateSuggestedPrice(
                              distance: widget.distance,
                              priceMultiplier: value.priceMultiplier!,
                            );
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),
                filteredPaymentMethods.isEmpty
                    ? const CircularProgressIndicator() // or SizedBox() if you want it hidden
                    : DropdownButtonFormField<PaymentMethod>(
                      value: filteredPaymentMethods.first,
                      decoration: const InputDecoration(
                        labelText: 'Select Payment Method',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          filteredPaymentMethods.map((method) {
                            return DropdownMenuItem<PaymentMethod>(
                              value: method,
                              child: Text(method.name),
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

                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Confirm"),
                  onPressed: () {
                    final enteredPrice = double.tryParse(_priceController.text);
                    if (enteredPrice != null) {
                      widget.onConfirm(
                        enteredPrice,
                        selectedTransport,
                        _paymentMethod,
                      );
                      Navigator.pop(context);
                    } else {
                      widget.onConfirm(
                        _suggestedPrice,
                        selectedTransport,
                        _paymentMethod,
                      );
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
