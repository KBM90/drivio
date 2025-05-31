import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/common/helpers/shared_preferences_helper.dart';
import 'package:http/http.dart' as http;
import '../models/user_payment_method.dart';

class PaymentMethodService {
  static const String baseUrl = Api.baseUrl; // change as needed
  static Future<List<UserPaymentMethod>> fetchUserPaymentMethods() async {
    try {
      final token = await SharedPreferencesHelper().getValue<String>(
        'auth_token',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/get-user-payment-methods'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> jsonList = jsonResponse['payment_methods'];
        return jsonList.map((e) => UserPaymentMethod.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch payment methods: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
