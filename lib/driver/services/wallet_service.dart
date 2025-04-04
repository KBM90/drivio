import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/driver/models/wallet.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // For storing token securely

class WalletService {
  // Fetch the wallet of the authenticated user
  Future<Wallet> getWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('${Api.baseUrl}/getWallet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Explicitly request JSON
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Wallet.fromJson(responseData);
      } else {
        // Try to parse error message from response
        final errorResponse = jsonDecode(response.body);

        throw Exception(
          errorResponse['message'] ??
              'Failed to load wallet. Status: ${response.statusCode}',
        );
      }
    } on FormatException catch (e) {
      throw Exception('Invalid server response format: $e');
    } catch (e) {
      throw Exception('Error fetching wallet: $e');
    }
  }
}
