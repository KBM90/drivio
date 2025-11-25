import 'package:drivio_app/common/services/auth_service.dart';
import 'package:drivio_app/driver/models/wallet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletService {
  // Fetch the wallet of the authenticated user
  Future<Wallet> getWallet() async {
    try {
      final internalUserId = await AuthService.getInternalUserId();
      if (internalUserId == null) {
        throw Exception('User not found');
      }

      final response =
          await Supabase.instance.client
              .from('wallets')
              .select()
              .eq('user_id', internalUserId)
              .single();

      return Wallet.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching wallet: $e');
    }
  }
}
