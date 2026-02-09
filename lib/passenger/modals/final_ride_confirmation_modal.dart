import 'package:drivio_app/common/constants/transport_constants.dart';
import 'package:drivio_app/common/helpers/price_helpers.dart';
import 'package:drivio_app/common/models/payment_method.dart';
import 'package:drivio_app/common/models/transporttype.dart';
import 'package:drivio_app/common/services/payment_methods_services.dart';
import 'package:flutter/material.dart';

class FinalRideConfirmationModal extends StatefulWidget {
  final double distance;
  final TransportType initialTransport;
  final String? initialInstructions; // Add initial instructions
  final Function(
    double price,
    TransportType transportType,
    PaymentMethod paymentMethod,
    String? instructions, // Add instructions to callback
  )
  onConfirm;

  const FinalRideConfirmationModal({
    super.key,
    required this.distance,
    required this.initialTransport,
    this.initialInstructions,
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
  final TextEditingController _instructionsController = TextEditingController();
  late double _suggestedPrice;
  String? _errorText;
  late PageController _pageController;
  int _selectedTransportIndex = 0;

  List<PaymentMethod> filteredPaymentMethods = [];

  // Map transport types to assets
  final Map<int, String> _transportAssets = {
    1: 'assets/transport_types/standard.png', // X Share
    2: 'assets/transport_types/green.png', // Green
    3: 'assets/transport_types/reserve.png', // Reserve
    4: 'assets/transport_types/taxi.png', // Taxi (Generic)
  };

  @override
  void initState() {
    super.initState();
    selectedTransport = widget.initialTransport;
    _instructionsController.text = widget.initialInstructions ?? '';
    _selectedTransportIndex = TransportConstants.transports.indexOf(
      widget.initialTransport,
    );
    if (_selectedTransportIndex == -1) _selectedTransportIndex = 0;

    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: _selectedTransportIndex,
    );

    _calculateSuggestedPrice();
    _loadUserPaymentMethods();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _priceController.dispose();
    _instructionsController.dispose();
    super.dispose();
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

    widget.onConfirm(
      enteredPrice,
      selectedTransport,
      _paymentMethod,
      _instructionsController.text,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 0, // Removed padding to allow carousel to go edge-to-edge
        right: 0,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            Column(
              children: [
                const SizedBox(height: 12),
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Confirm your ride",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Transport Carousel
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: TransportConstants.transports.length,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedTransportIndex = index;
                        selectedTransport =
                            TransportConstants.transports[index];
                        _priceController.clear();
                        _calculateSuggestedPrice();
                      });
                    },
                    itemBuilder: (context, index) {
                      final transport = TransportConstants.transports[index];
                      final isSelected = index == _selectedTransportIndex;
                      final assetPath =
                          _transportAssets[transport.id] ??
                          'assets/cars/drivio_car_standard.png';

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              isSelected
                                  ? Border.all(color: Colors.black, width: 2)
                                  : Border.all(color: Colors.grey[200]!),
                          boxShadow:
                              isSelected
                                  ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            children: [
                              // 1. Background Image
                              Positioned.fill(
                                child: Image.asset(
                                  assetPath,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // 2. Gradient Overlay for Text Readability
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    24,
                                    12,
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                        Colors.black.withOpacity(0.9),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        transport.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        transport.description ?? '',
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          // Transport name is now visible in the carousel
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

                      // Driver Instructions Input
                      TextField(
                        controller: _instructionsController,
                        maxLines: 2,
                        minLines: 1,
                        decoration: InputDecoration(
                          labelText: 'Notes for driver',
                          hintText: 'e.g. "Wait at the main gate"',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.edit_note),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment Method Dropdown
                      filteredPaymentMethods.isEmpty
                          ? const Center(child: CircularProgressIndicator())
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
          ],
        ),
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
