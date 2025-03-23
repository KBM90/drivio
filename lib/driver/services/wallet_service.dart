import 'dart:convert';
import 'package:drivio_app/common/constants/api.dart';
import 'package:drivio_app/driver/models/wallet.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // For storing token securely

class WalletService {
  // Fetch the wallet of the authenticated user
  Future<Wallet> getWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token'); // For storing auth token
    // Get the auth token from secure storage

    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('${Api.baseUrl}/getWallet'),
      headers: {
        'Authorization': 'Bearer $token', // Pass the token in the header
      },
    );

    if (response.statusCode == 200) {
      // If the API returns a 200 status code, parse the wallet data
      await prefs.setString('wallet', response.body);
      return Wallet.fromJson(jsonDecode(response.body));
    } else {
      // If the wallet is not found or an error occurs
      throw Exception('Failed to load wallet');
    }
  }
}
