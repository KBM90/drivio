import 'package:drivio_app/common/models/payment_method.dart';

class PaymentMethodsConstants {
  static List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: 1, name: 'Cash'),
    PaymentMethod(id: 2, name: 'Credit Card'),
    PaymentMethod(id: 3, name: 'Bank Account'),
    PaymentMethod(id: 4, name: 'Crypto Wallet'),
    PaymentMethod(id: 5, name: 'Apple Pay', requiresDetails: true),
    PaymentMethod(id: 6, name: 'Google Pay'),
    PaymentMethod(id: 7, name: 'Bank Transfer'),
    PaymentMethod(id: 8, name: 'Bank Deposit'),
    PaymentMethod(id: 9, name: 'Paypal'),
    PaymentMethod(id: 10, name: 'Venmo'),
  ];
}
