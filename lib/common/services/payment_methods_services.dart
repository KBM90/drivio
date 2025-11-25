import 'package:drivio_app/common/models/payment_method.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentMethodService {
  static Future<List<PaymentMethod>> fetchPaymentMethods() async {
    try {
      final response =
          await Supabase.instance.client.from('payment_methods').select();

      final List<dynamic> data = response;
      return data.map((e) => PaymentMethod.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching payment methods: $e');
    }
  }
}
