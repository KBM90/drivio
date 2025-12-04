import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drivio_app/common/services/paypal_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  bool _isLoading = true;
  List<UserPaymentMethod> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      setState(() => _isLoading = true);

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No authenticated user');
        setState(() => _isLoading = false);
        return;
      }

      // Get user's internal ID
      final userResponse =
          await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('user_id', userId)
              .single();

      final internalUserId = userResponse['id'];

      // Fetch user's payment methods with payment method details
      final response = await Supabase.instance.client
          .from('user_payment_methods')
          .select('*, payment_methods!inner(name)')
          .eq('user_id', internalUserId);

      final List<dynamic> data = response;

      _paymentMethods =
          data.map((item) {
            final paymentMethodName = item['payment_methods']['name'] as String;
            String? details;

            // Format details based on payment method type
            if (paymentMethodName == 'PayPal' && item['details'] != null) {
              final paypalEmail = item['details']['paypal_email'];
              final verified = item['details']['paypal_verified'] ?? false;
              details =
                  '$paypalEmail ${verified ? '(Verified)' : '(Unverified)'}';
            } else if (item['details'] != null) {
              details = item['details'].toString();
            }

            return UserPaymentMethod(
              id: item['id'],
              methodName: paymentMethodName,
              details: details,
              isDefault: item['is_default'] ?? false,
            );
          }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Error loading payment methods: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddPaymentMethodDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Payment Method'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose a payment method to link:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  // Cash - Already default
                  _buildPaymentMethodCard(
                    icon: Icons.money,
                    title: 'Cash',
                    subtitle: 'Default payment method',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cash is already your default payment method',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Credit/Debit Card via Stripe
                  _buildPaymentMethodCard(
                    icon: Icons.credit_card,
                    title: 'Credit/Debit Card',
                    subtitle: 'Visa, Mastercard via Stripe',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(context);
                      await _linkStripeCard();
                    },
                  ),
                  const SizedBox(height: 12),

                  // PayPal
                  _buildPaymentMethodCard(
                    icon: Icons.payment,
                    title: 'PayPal',
                    subtitle: 'Link your PayPal account',
                    color: const Color(0xFF0070BA),
                    onTap: () async {
                      Navigator.pop(context);
                      await _linkPayPal();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Moroccan Cards via CMI
                  _buildPaymentMethodCard(
                    icon: Icons.account_balance,
                    title: 'Moroccan Bank Card',
                    subtitle: 'Local cards via CMI',
                    color: Colors.orange,
                    onTap: () async {
                      Navigator.pop(context);
                      await _linkCMICard();
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _linkStripeCard() async {
    try {
      // TODO: Integrate Stripe payment sheet
      // 1. Add stripe_flutter package to pubspec.yaml
      // 2. Initialize Stripe with publishable key
      // 3. Create payment method using Stripe.instance.presentPaymentSheet()
      // 4. Save payment method ID to database

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stripe integration coming soon...'),
          backgroundColor: Colors.blue,
        ),
      );

      debugPrint('🔗 Linking Stripe card...');
    } catch (e) {
      debugPrint('❌ Error linking Stripe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error linking card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _linkPayPal() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Initiate PayPal account linking
      final paypalDetails = await PayPalService.linkPayPalAccount(context);

      // Close loading indicator
      if (mounted) Navigator.of(context).pop();

      if (paypalDetails == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PayPal linking cancelled or failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Save PayPal payment method to database
      final saved = await PayPalService.savePayPalPaymentMethod(paypalDetails);

      if (!mounted) return;

      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PayPal account linked: ${paypalDetails['paypal_email']}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload payment methods to show the new PayPal account
        await _loadPaymentMethods();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save PayPal account'),
            backgroundColor: Colors.red,
          ),
        );
      }

      debugPrint('🔗 PayPal account linked successfully');
    } catch (e) {
      debugPrint('❌ Error linking PayPal: $e');
      if (mounted) {
        // Close loading indicator if still open
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error linking PayPal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _linkCMICard() async {
    try {
      // TODO: Integrate CMI payment gateway (Morocco)
      // 1. Use webview to redirect to CMI payment page
      // 2. Handle callback with payment token
      // 3. Save card token to database
      // CMI is the main payment gateway in Morocco for local cards

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CMI integration coming soon...'),
          backgroundColor: Colors.orange,
        ),
      );

      debugPrint('🔗 Linking CMI card...');
    } catch (e) {
      debugPrint('❌ Error linking CMI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error linking card: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setDefaultPaymentMethod(int methodId) async {
    try {
      // TODO: Update default payment method in database
      _loadPaymentMethods();
    } catch (e) {
      debugPrint('❌ Error setting default payment method: $e');
    }
  }

  Future<void> _deletePaymentMethod(int methodId) async {
    try {
      // TODO: Delete payment method from database
      _loadPaymentMethods();
    } catch (e) {
      debugPrint('❌ Error deleting payment method: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPaymentMethodDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _paymentMethods.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No payment methods added',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add a payment method',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddPaymentMethodDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Payment Method'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = _paymentMethods[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        _getPaymentIcon(method.methodName),
                        size: 32,
                      ),
                      title: Text(
                        method.methodName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(method.details ?? 'No details'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (method.isDefault)
                            const Chip(
                              label: Text('Default'),
                              backgroundColor: Colors.green,
                              labelStyle: TextStyle(color: Colors.white),
                            )
                          else
                            TextButton(
                              onPressed:
                                  () => _setDefaultPaymentMethod(method.id),
                              child: const Text('Set Default'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePaymentMethod(method.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  IconData _getPaymentIcon(String methodName) {
    switch (methodName.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'bank transfer':
        return Icons.account_balance;
      case 'credit card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }
}

// Temporary model for payment methods
class UserPaymentMethod {
  final int id;
  final String methodName;
  final String? details;
  final bool isDefault;

  UserPaymentMethod({
    required this.id,
    required this.methodName,
    this.details,
    this.isDefault = false,
  });
}
